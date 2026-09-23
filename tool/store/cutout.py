#!/usr/bin/env python3
"""Turn a 69labs "transparent background" render into a real cutout.

The image models paint the transparency checkerboard into the pixels instead of
writing an alpha channel, so the file comes back RGB with a grey-and-white grid
behind the subject. Both checker tones are neutral (zero saturation) and bright,
which nothing in a photographed plant is, so keying on that pair is enough.

Ask the model for a flat magenta backdrop and key that instead (`--magenta`) —
it is the only mode that is reliable for a bright subject, because a white cloud
is indistinguishable from the checker's white tone.

Two checker modes. The default keys only the checker that is connected to the border,
which is what a bright subject (a white cloud, a pale flower) needs — a global
key eats holes out of it. `--global` keys every checker pixel anywhere, for a
subject whose outline encloses some background the border cannot reach.

    python3 tool/store/cutout.py <in.png> <out.png> [width] [--global]
"""
import sys
from collections import deque

from PIL import Image, ImageFilter


def is_checker(p):
    return (max(p) - min(p)) < 18 and min(p) > 185


def is_magenta(p):
    r, g, b = p
    return r > 120 and b > 120 and g < min(r, b) - 45


def border_connected(px, w, h):
    """Checker pixels reachable from the edge — the background, holes excluded."""
    seen = bytearray(w * h)
    q = deque()

    def push(x, y):
        i = y * w + x
        if not seen[i] and is_checker(px[x, y]):
            seen[i] = 1
            q.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)
    while q:
        x, y = q.popleft()
        if x > 0:
            push(x - 1, y)
        if x < w - 1:
            push(x + 1, y)
        if y > 0:
            push(x, y - 1)
        if y < h - 1:
            push(x, y + 1)
    return seen


def cut(src, dst, width=1024, everywhere=False, magenta=False):
    im = Image.open(src).convert("RGB")
    im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    px = im.load()
    w, h = im.size
    mask = Image.new("L", (w, h))
    if magenta:
        mask.putdata([0 if is_magenta(px[x, y]) else 255 for y in range(h) for x in range(w)])
    elif everywhere:
        mask.putdata([0 if is_checker(px[x, y]) else 255 for y in range(h) for x in range(w)])
    else:
        seen = border_connected(px, w, h)
        mask.putdata([0 if seen[i] else 255 for i in range(w * h)])
    # The median pass drops the stray checker pixels that survive between the
    # subject's fine edges (leaf hairs, root tips); the blur feathers the edge so
    # it does not read as a sticker against the panel.
    mask = mask.filter(ImageFilter.MedianFilter(5)).filter(ImageFilter.GaussianBlur(1.1))
    out = im.convert("RGBA")
    out.putalpha(mask)
    out = out.crop(out.getbbox())
    out.save(dst)
    return out.size


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    src, dst = args[0], args[1]
    width = int(args[2]) if len(args) > 2 else 1024
    print(dst, cut(src, dst, width, everywhere="--global" in sys.argv,
                   magenta="--magenta" in sys.argv))
