#!/usr/bin/env python3
"""Key a flat magenta background out of a generated image and write a PNG.

The 69labs image API answers with JPEG, which has no alpha: asking it for a
"transparent background" gets you a drawn checkerboard, not transparency. So
the specs ask for a flat magenta (#FF00FF) field instead and this keys it out.

Magenta is the one hue the mascot has none of: the key is `min(R, B) - G`,
which is +255 on the background and negative on terracotta, green and pink,
with the soft edge landing in between. Pixels in that band get partial alpha
and are de-spilled, so the edge keeps its own colour instead of a pink fringe.

Not to be confused with `tool/store/cutout.py`, which keys the same magenta for
the store screenshots. That one resizes to a target width and crops to the
subject's bounding box, which is right for a panel illustration and fatal here:
the mascot's body and seedling layers are derived by subtracting one render's
alpha from another's, so every file has to stay on the same untouched canvas.
It also keys hard, then feathers with a median and a blur; this one fades across
a band and de-spills instead, because a glossy cut-out's anti-aliased edge keeps
a pink rim otherwise.

Usage:
    python3 tool/cutout.py <in.jpg|dir> [out.png|dir]
"""

import os
import sys

from PIL import Image

# Below LOW the pixel is the character, above HIGH it is background; between
# the two it is a JPEG-softened edge and gets partial alpha.
LOW, HIGH = 30, 110


def cut(src, dst):
    im = Image.open(src).convert("RGB")
    px = im.load()
    out = Image.new("RGBA", im.size)
    op = out.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            key = min(r, b) - g
            if key >= HIGH:
                op[x, y] = (0, 0, 0, 0)
                continue
            if key <= LOW:
                op[x, y] = (r, g, b, 255)
                continue
            # Partial edge: fade out, and pull the magenta back out of the
            # colour so the rim does not read pink over a light background.
            t = (key - LOW) / (HIGH - LOW)
            spill = key - LOW
            op[x, y] = (
                max(0, r - spill),
                g,
                max(0, b - spill),
                int(255 * (1 - t)),
            )
    out.save(dst)
    return out


def main():
    src = sys.argv[1]
    dst = sys.argv[2] if len(sys.argv) > 2 else None
    if os.path.isdir(src):
        dst = dst or src
        os.makedirs(dst, exist_ok=True)
        for name in sorted(os.listdir(src)):
            if not name.lower().endswith((".jpg", ".jpeg")):
                continue
            out = os.path.join(dst, os.path.splitext(name)[0] + ".png")
            cut(os.path.join(src, name), out)
            print(f"wrote {out}")
    else:
        out = dst or os.path.splitext(src)[0] + ".png"
        cut(src, out)
        print(f"wrote {out}")


if __name__ == "__main__":
    main()
