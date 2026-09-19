# Cropsy — mobile (Flutter)

Container/balcony-first vegetable-growing app for NL/EU: **"what to do in your
garden this week,"** with planting dates + reminders driven by real Dutch/EU
weather (KNMI/Open-Meteo), not US zones. iOS + Android, single Flutter codebase.

Companion to the backend repo `NeilAlvn/cropsy` (Next.js on Vercel + Supabase).
The seam between them is `docs/API-CONTRACT.md` in that repo; the product spec
and phased build plan is `docs/PRD.md` there (locked v1.0, 2026-09-13).

> **Status (2026-09-19):** feature-complete for the free tier and premium (PRD Phases 0–3 done, Phase 4 launch tail open). `flutter run` shows the product. The sections below describe the engine core and are still accurate; the screens live in `lib/features/`.

## What's here now

- **`lib/timing/`** — the offline **base-schedule engine**, a line-for-line port
  of the backend's `src/timing/*`:
  - `dates.dart` — UTC calendar-day math (parity with `dates.ts`).
  - `types.dart` — `Crop`, `CropMethod`, `FrostProfile`, `ScheduledWindow`.
  - `engine.dart` — `scheduleCrop` / `scheduleGarden` / `windowsActiveInRange`
    (the deterministic base layer; **no network, no clock** — runs fully offline).
  - `weather_adjust.dart` — the online overlay mirror (`adjustTasks`): skip-when-wet,
    defer-below-soil-temp, bring-forward-on-heat. Server is source of truth; this
    mirror lets a hint render from cached weather without a round-trip.
  - `crop_snapshot.dart` — parser for the bundled snapshot (same shape as
    `GET /api/crops`).
- **`assets/data/crops-snapshot.json`** — 60 verified crops, bundled so a cold
  start needs zero network. Byte-identical to the API response; carries the
  content-hash `version` (`33d3e8f955a94c8c`) for `If-None-Match` delta sync.
- **`test/`** — parity tests proving the Dart engine reproduces the backend
  fixtures **to the day**:
  - `base_schedule_test.dart` -> `docs/fixtures/base-schedule.fixture.json`
  - `weather_adjust_test.dart` -> `docs/fixtures/weather-adjust.fixture.json`
    (exact actions, target dates, and localized reason strings)

Run: `flutter test` and `flutter analyze` (both green).

## Architecture decisions (locked with backend)

- **Flutter, not React Native** — no web product kills RN's main edge; Flutter's
  reactive local DB + pixel control fit an offline-first, design-led app.
- **Offline-first, local-first.** Drift (SQLite) will be the source of truth for
  the UI; writes go optimistic -> outbox -> upsert on reconnect. Single-user app
  means conflicts resolve **last-write-wins on `updated_at`** (no CRDTs).
  PowerSync is the escape hatch, not day one.
- **Two-layer timing.** Base schedule computed **on-device** (this engine);
  weather adjustment is an optional online overlay that degrades to the base when
  offline — never a blank screen.
- **Watering is client-generated** (recurring, pot-size + weather driven, not
  frost-relative); the server adjuster only ever *moves or skips* tasks it's given.

## Bundle ID

`applicationId` / bundle id is **`com.cropsyapp.app`**, frozen 2026-09-13 (App Store Connect app 6811652686). History:

- an **EUIPO trademark check** on "Cropsy" is outstanding — *Cropsy Technologies
  Ltd* (NZ agritech) already trades under the name;
- the product name may become **"Pluk"**.

The name stayed Cropsy; the ASC record exists, so the id no longer changes.

## Next

See `docs/PRD.md` §11 Phase 4 in the backend repo.

## Toolchain

Flutter 3.47.4 (stable) · Dart 3.12.
