# TestFlight round one — design

Date: 2026-09-23
Status: approved

Six changes asked for after the first TestFlight build. Three of them turned
out to be discoverability problems rather than missing features: the theme
switch, the language switch, account deletion, the FAQ and the support links
all already exist in `SettingsScreen`, reachable only through a single
"Settings & Sync" row on the profile. The design below surfaces those and
builds the parts that genuinely do not exist yet.

Out of scope, dropped during brainstorming: a location on/off switch. GPS is
only ever touched when the gardener taps "use my current location", so there is
nothing running to turn off.

## A. Light mode

The palette already ships both schemes in full (`design/colors.dart`), and
`AppTheme` already resolves system/light/dark and persists the choice in
`app_meta`. Nothing needs to be built. Two bugs stop the dark scheme from
looking right, and the control needs to be somewhere a person can find it.

1. `features/home/home_screen.dart` hardcodes `SystemUiOverlayStyle.dark` for
   the home band. In the dark scheme the status bar then draws dark glyphs on a
   dark band. Derive the style from `AppColors.isDark`.
2. `design/glass.dart` paints the specular edge at `Colors.white` 0.55 and the
   sheen gradient at 0.22 to 0.02, in both schemes. On the dark canvas the
   floating tab pill gains a bright white ring. Scale both by scheme.

The control itself moves into the settings hub (section D).

Verification is by screenshot, not by reading: build, boot the simulator, and
capture all five tabs plus the profile in both schemes. Anything that ignores
the palette gets fixed in the same pass.

## B. Daily weather on Home

`features/garden/weather_service.dart` already fetches `precipitation_sum`,
`temperature_2m_min` and `temperature_2m_max` for seven days back and seven
ahead from Open-Meteo, cached in `app_meta` for six hours. Home never shows any
of it; weather reaches the screen only as per-task badges and as the mascot's
line when a watering was skipped.

- Add `weathercode` to the existing `daily` parameter list. One more field in
  the same request and the same cache, giving a condition to draw an icon from.
- Expose the observations on `GardenRepository` so a widget can read today and
  the days after it without touching the service.
- Add a `_TodayWeather` card to Home, above `_TodaysCare`: today's high and
  low, rain in mm, a condition icon, a seven-day strip, and one line saying
  what the weather changed — reusing the hint reason the timing engine already
  writes.

No new package, no new service, no second network call.

## C. Season path — more stops

The path already interleaves plant nodes, pending tasks and markers by date
(`features/season/season_rows.dart`), and `season_markers.dart` emits frost
dates, ijsheiligen, the seed order, the monthly photo, the payoff, the recap
and the day's weather change. More steps means more marker kinds, not a new
screen and not a new row shape.

Phase 1, from content the snapshot already carries:

- **Checklist stops.** `ContentSnapshot.checklist` holds monthly items with a
  title, a body and an optional crop link. Home renders them; the path does
  not. One stop per item, on a date inside its month.
- **Companion tips.** `CompanionPair` carries two crop slugs and a reason. For
  a pair where the gardener grows one side and not the other, a stop suggesting
  the partner.
- **Collection spotlight.** `ContentCollection` carries a title, an intro and a
  crop list. One stop per quiet month pointing at a collection that suits it.

Phase 2, from the gardener's own history — the first sowing of the year, the
harvest milestones at 1/10/25/50/100, the longest streak run reached, and a
plant with a photo this month and an older one to set it beside. Shipped after
phase 1. Capped at five milestone stops in a whole year, and a first-time
gardener with no history gets none of them.

Streak milestones are dated by reusing `computeStreak` for each candidate day
rather than re-deriving the runs, so freeze days are honoured and a milestone
can never disagree with the streak count on Home. That is O(days²) over a year,
which is nothing, and it carries a `ponytail:` comment saying so.

`seasonMarkers` stays a pure function over `MarkerFacts`, so the new kinds are
tested the way the existing ones are, in `test/season_markers_test.dart`.

## D. Profile becomes the settings hub

`ProfileScreen` keeps its identity card and three stat tiles, then carries
grouped rows for everything the app can be told:

- **Jouw tuin** — region, garden profile, membership
- **Weergave** — theme, language
- **Meldingen** — reminders, seasonal mail, analytics
- **Toegankelijkheid** — haptics, reduced motion
- **Account** — sign in and sync, export, change password, change email, delete
  account
- **Help** — FAQ, contact, privacy, terms

`SettingsScreen` shrinks to the account and sync forms and is reached from the
Account row. At 584 lines it is already too big for what it does, so each group
becomes its own file under `features/settings/`.

New in this section:

- **Garden profile editor.** `Gardens` already has `kind`, `sizeM2` and
  `sunHours`, filled during onboarding and never editable afterwards. A sheet
  writing those three columns covers moving house and finding more room.
- **Accessibility preferences.** Haptics on/off and reduced motion, stored in
  `Profiles.preferences` — a JSON column that already syncs, so no migration.
  `Haptics` gains an enabled flag; `Motion.of` ORs the app preference with the
  platform setting it already reads, so turning it on is additive and the OS
  setting still wins when it is set.

The theme choice stays in `app_meta` rather than moving to preferences: it
describes the device, not the account, and should not follow a sign-in to a
second phone.

Account deletion stays gated behind being signed in. A device-only garden has
no account to delete, and deleting the app covers it.

## E. Search in Diagnose

A search field above the plant-part chips in
`features/diagnose/diagnose_screen.dart`, matching problem names, symptoms and
affected crops, composed with the part filter rather than replacing it.

## Strings

Every new string lands in `lib/l10n/strings.dart` before the implementation
work starts, so that the file has one author and the parallel work does not
collide in it.
