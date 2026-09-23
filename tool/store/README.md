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

`upload/en-US/` and `upload/nl-NL/` hold the finals, named so that alphabetical
order is the order they should appear in the store listing. Drag each folder
into the matching localisation in App Store Connect → App Store → Screenshots
(6.9" Display), and into Play Console → Store listing → Phone screenshots.

Order is deliberate: the first three are what shows in search results.

## Recapture list

The captures are hand-taken on a simulator. Two are worth retaking:

- `en-diagnose` / `nl-diagnose` currently show the problem catalogue. A real
  photo-diagnosis result (leaf photo + verdict) would match the headline and is
  the single highest-leverage change to shot 1.
- `en-timeline` / `nl-timeline` are text-heavy at thumbnail size.
