# Generated illustration

The mascot poses (`assets/mascot`), the task and weather marks (`assets/marks`)
and the illustration in `assets/illustration` were generated on the 69labs image
API with `nano-banana-2`, from the prompts in `tool/gen_images.py`'s spec files.
`idle.jpg` is the reference every other pose was generated against, which is what
keeps the character consistent.

Regenerate or extend with:

    LABS69_API_KEY=... python3 tool/gen_images.py <spec.json> <out-dir>

Existing files are skipped, so a re-run only fills gaps.
