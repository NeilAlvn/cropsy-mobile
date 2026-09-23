#!/usr/bin/env python3
"""Split a mascot pose into a body layer and a seedling layer.

Asking the model for a part on its own does not work — it draws the whole
character anyway. Asking it for the whole character with ONE thing erased does
work, and it holds the rest in register, so the seedling is recovered by
subtracting the erased version's alpha from the full one's.

The seedling is the only part worth splitting out: it sways. The leaf-arms sit
flush against the pot with no limb between, so rotating them buries them in the
pot rather than waving them — those stay whole-pose art.

Usage:
    LABS69_API_KEY=... python3 tool/mascot_layers.py idle wave thinking
"""

import os
import sys

from PIL import Image, ImageChops, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cutout
import gen_images as g

MASTERS = "tool/out/mascot"
OUT = "assets/mascot"
SIZE = 512

PROMPT = (
    "Redraw the reference image with the seedling — the stem and the leaves growing out of the top of the "
    "pot — completely ERASED. Everything else stays EXACTLY as it is: the pot, its face, its soil, its side "
    "leaf-arms, its legs and any prop keep the same position, scale, angle and lighting, down to the pixel. "
    "Do not re-centre, do not resize, do not redraw anything but the removal. Keep the glossy 3D cartoon "
    "style. The background must be a single flat uniform pure magenta (hex #FF00FF) filling every pixel that "
    "is not the character. No shadow, no gradient, no checkerboard, no ground."
)


def split(pose):
    master = f"{MASTERS}/{pose}.png"
    nostem_jpg = f"{MASTERS}/{pose}_nostem.jpg"
    nostem_png = f"{MASTERS}/{pose}_nostem.png"

    if not os.path.exists(nostem_png):
        job = g.generate(PROMPT, "1:1", [g.data_uri(master)], "1k")
        g.download(job, nostem_jpg)
        cutout.cut(nostem_jpg, nostem_png)
        os.remove(nostem_jpg)
        print(f"generated {nostem_png}")

    full = Image.open(master).convert("RGBA")
    body = Image.open(nostem_png).convert("RGBA")
    fa, ba = full.getchannel("A"), body.getchannel("A")
    # Grow the body's alpha before subtracting: the two renders agree to within
    # a few pixels, and without the margin the seedling layer keeps a rim of pot.
    stem_mask = ImageChops.subtract(fa, ba.filter(ImageFilter.MaxFilter(7)))
    stem = full.copy()
    stem.putalpha(ImageChops.multiply(fa, stem_mask))

    for name, im in ((f"{pose}_body", body), (f"{pose}_stem", stem)):
        im.resize((SIZE, SIZE), Image.LANCZOS).save(f"{OUT}/{name}.png", optimize=True)
        print(f"wrote {OUT}/{name}.png")

    # Where the stem meets the soil, as a fraction of the image: the pivot the
    # sway rotates about. Written next to the art so Flutter does not guess.
    box = stem_mask.getbbox()
    if box:
        print(f"  pivot {pose}: x={(box[0]+box[2])/2/full.width:.4f} "
              f"y={box[3]/full.height:.4f}")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        split(p)
