# Store screenshots

Framed App Store / Play Store screenshots, built from the raw captures in
`../shots/`. Layout follows the pattern PictureThis and the other top plant apps
use: brand-green panel, one bold claim per shot, the real screen underneath
bleeding off the bottom edge, one callout that points at the thing the claim
promises.

## Rebuild

```
tool/store/render.sh
```

Headless Chrome renders each entry of `SHOTS` in `frame.html` at 1320×2868 into
`out/`. That is the App Store 6.9" size; App Store Connect scales it down for
the smaller device sizes, and Play Store accepts it as a phone screenshot.

Everything lives in `frame.html`: headline, which capture, how far the capture
is scrolled inside the frame (`y`), and the callout positions. Change a screen
in the app, retake the capture into `../shots/` with the same filename, rerun.

## Upload

`upload/<locale>/` holds the finals, `1.png` … `6.png` in listing order (the
first three show in search results):

| Folder | App Store Connect locale | Play Console listing |
|---|---|---|
| `upload/en-US/` | English (U.S.) | en-US |
| `upload/en-GB/` | English (U.K.) | en-GB |
| `upload/en-AU/` | English (Australia) | en-AU |
| `upload/nl-NL/` | Dutch | nl-NL |

iOS: `python3 tool/store/asc_listing.py --shots en-US,en-GB,en-AU` (dry run;
add `--apply`) replaces the 6.9" (APP_IPHONE_67) set per locale and uploads the
files one at a time, so the order is the upload order. It also pushes title,
subtitle, keywords, description and What's New from `metadata/*.md`, and creates
a missing localisation (en-AU). By hand in Media Manager: also one file at a
time — several files in one go land in completion order.

## Captures (`../shots/`, gitignored)

iPhone 17 Pro Max (1320×2868), app language English, five crops growing:
`us-*` Chicago (en_US), `gb-*` Leeds (en_GB), `au-*` Melbourne (en_AU); screens
`season`, `home`, `explore`, `garden`, `timeline` (lettuce detail). Shot 1 reuses
`en-scan.png` for all three. For the capture build only, `premium` was forced
true in `purchase_service.dart` (unblurred season path, no plant cap) and
reverted afterwards.

## Recapture list

The captures are hand-taken on a simulator. Two are worth retaking:

- `en-diagnose` / `nl-diagnose` currently show the problem catalogue. A real
  photo-diagnosis result (leaf photo + verdict) would match the headline and is
  the single highest-leverage change to shot 1.
- `en-timeline` / `nl-timeline` are text-heavy at thumbnail size.
