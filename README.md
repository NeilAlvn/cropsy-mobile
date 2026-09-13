# Cropsy — mobile (Flutter)

Container/balcony-first vegetable-growing app for NL/EU: **"what to do in your
garden this week,"** with planting dates + reminders driven by real Dutch/EU
weather (KNMI/Open-Meteo), not US zones. iOS + Android, single Flutter codebase.

Companion to the backend repo `NeilAlvn/cropsy` (Next.js on Vercel + Supabase).
The seam between them is `docs/API-CONTRACT.md` in that repo; the product spec
and phased build plan is `docs/PRD.md` there (locked v1.0, 2026-09-13).

> **Status: pre-UX shell.** Product screens are intentionally **not** built yet —
> the design direction is still being decided, so this repo currently holds only
> the *design-independent* core: the offline timing engine, the bundled crop
> data, and the project scaffold. `flutter run` shows a developer harness, not
> product UI.

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

## Bundle ID is provisional

`applicationId` / bundle id is `app.visiontech.cropsy` (VisionTech B.V. is the
stable legal entity). The `cropsy` segment is **not yet final**:

- an **EUIPO trademark check** on "Cropsy" is outstanding — *Cropsy Technologies
  Ltd* (NZ agritech) already trades under the name;
- the product name may become **"Pluk"**.

No App Store / Play record exists yet, so changing it is still free. **Finalize
the bundle id before creating any store record** — that's the expensive-to-change
moment.

## Next (not started — most gated on design or an account decision)

- Drift schema for the syncable tables (`gardens`, `garden_plants`, `tasks`,
  `journal_entries`) mirroring API-contract section 6, plus the outbox/delta-sync
  layer. **Gated on** the Supabase auth handshake (provider choice still open).
- RevenueCat (`purchases_flutter`), local notifications, Supabase client wiring —
  reused patterns from Farmsy.
- Product screens (F1–F7) once Luuk greenlights a design direction.

## Toolchain

Flutter 3.44.8 (stable) · Dart 3.12.2.
