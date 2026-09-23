# Generated illustration

The mascot poses (`assets/mascot`), the task and weather marks (`assets/marks`),
the onboarding photographs (`assets/onboarding`) and the illustration in
`assets/illustration` were generated on the 69labs image API, from the specs in
`tool/specs/`.

The poses were drawn at 256 px in 2026-09 and upscaled to 1024 px on 2026-09-23,
each pose against its own earlier file, so the character is the same one — not a
redraw. They ship at 512 px.

`idle`, `wave` and `thinking` also ship split in two, `<pose>_body.png` plus
`<pose>_stem.png`, so the seedling can sway on its own; `idle_body_blink.png` is
the same body with its eyes closed. `tool/mascot_layers.py` cuts those, and
`lib/design/mascot.dart` is the only file that knows they exist.

Regenerate or extend with:

    LABS69_API_KEY=... python3 tool/gen_images.py tool/specs/<spec>.json tool/out/<dir>

Existing files are skipped, so a re-run only fills gaps. Read
`tool/specs/README.md` first — the API returns JPEG with no alpha, which is why
everything is drawn on magenta and keyed.
