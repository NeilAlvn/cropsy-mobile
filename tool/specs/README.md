# Image specs

Each spec is one run of `tool/gen_images.py`:

    LABS69_API_KEY=... python3 tool/gen_images.py tool/specs/<spec>.json <out-dir>

Files that already exist are skipped, so a re-run only fills gaps.

| Spec | Out dir | What it does |
|---|---|---|
| `mascot.json` | `tool/out/mascot` | Upscales the 12 poses to 1024 px. `_ref_each` points each entry at its own existing `assets/mascot/<pose>.png`, so every pose is redrawn against itself — an upscale, not a reinvention. |
| `hero.json` | `tool/out/hero` | The three onboarding photographs at 4k. |

Masters land in `tool/out/` (gitignored) and are downscaled into `assets/` by
hand: 512 px for the mascot (the largest on-screen use is 96 pt, which is 288 px
at 3×) and 1536 px wide for the heroes (a 1290 px screen, full bleed, plus
`SlowPan`'s 12 % zoom).

`tool/mascot_layers.py` is separate, because it is a different job: it splits a
pose into `<pose>_body.png` and `<pose>_stem.png` so the seedling can sway.

    LABS69_API_KEY=... python3 tool/mascot_layers.py idle wave thinking

## Two things the API does that the docs (which don't exist) won't tell you

**Output is always JPEG.** There is no alpha, ever. Asking for a transparent
background gets you a *drawn checkerboard*. So every spec that needs alpha asks
for a flat `#FF00FF` field and sets `_cutout: true`, which runs `tool/cutout.py`
— the key is `min(R, B) - G`, which is +255 on magenta and negative on
terracotta, green and pink.

One consequence: **translucent white does not survive the key.** White
snowflakes over magenta come back pink and half-transparent. The `frost` pose
asks for opaque pale ice-blue instead. Anything else with white mist, steam or
glass will need the same treatment.

**`imageUrls` accepts a `data:` URI**, so a file already in the repo can be the
reference without hosting it anywhere. That is the whole reason the mascot could
be upscaled rather than redrawn, and why the app icon did not have to change.
Pin the style in the prompt too ("glossy 3D toy, no photographic texture, no
leaf veins, no realistic eyes") or the redraw drifts photoreal.

## Still soft

`assets/marks` and `assets/nodes` are 176 px and drawn at 40–64 pt. The same
`_ref_each` upscale would fix them — about 30 images — but nobody has looked at
whether all 30 still match the art direction.
