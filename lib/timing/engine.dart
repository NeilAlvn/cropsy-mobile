/// The timing engine — the deterministic BASE layer.
///
/// Turns frost-relative crop rules + a location's frost dates into concrete,
/// dated windows. Intentionally pure and dependency-free: no weather, no
/// network, no clock. That is what lets this client run the exact same logic
/// fully offline (the "base schedule" from the reminder split). The
/// weather-aware ADJUSTMENT is a separate online layer applied on top — see
/// `weather_adjust.dart`. This file must never reach for it.
///
/// Direct port of the backend `src/timing/engine.ts`; proven equal to the day
/// against `docs/fixtures/base-schedule.fixture.json` in the tests.
library;

import 'dates.dart';
import 'heat.dart';
import 'types.dart';

DateTime _anchorDate(CropMethod method, FrostProfile frost) => parseIso(
  method.anchor == FrostAnchor.lastFrost ? frost.lastFrost : frost.firstFrost,
);

/// Compute the dated windows for a single crop at a location.
/// Deterministic: same crop + same frost profile always yields the same result.
List<ScheduledWindow> scheduleCrop(Crop crop, FrostProfile frost) {
  final hasClimate = frost.weeklyTmax?.length == 52;
  // (auto, window) in method order; window null = trimmed away.
  final items = [
    for (final method in crop.methods)
      if (!method.needsClimate || hasClimate)
        (
          auto: method.needsClimate,
          window: () {
            final anchor = _anchorDate(method, frost);
            return trimForHeat(
              ScheduledWindow(
                cropSlug: crop.slug,
                method: method.type,
                start: toIso(addWeeks(anchor, method.startWeeks)),
                end: toIso(addWeeks(anchor, method.endWeeks)),
                minSoilC: method.minSoilC,
                note: method.note,
              ),
              crop.maxC,
              frost.weeklyTmax,
              method.needsClimate ? autumnMinC : null,
            );
          }(),
          type: method.type,
        ),
  ];
  // Sowing indoors only makes sense if there is still a time to plant out.
  // Only the spring pairing (no needsClimate) counts.
  final spring = items
      .where((it) => !it.auto && it.type == MethodType.transplant)
      .toList();
  final keepsTransplant = spring.any((it) => it.window != null);
  return [
    for (final it in items)
      if (it.window case final w?)
        if (w.method != MethodType.sowIndoor ||
            spring.isEmpty ||
            keepsTransplant)
          w,
  ];
}

/// Schedule many crops at once (e.g. everything in a user's garden), sorted by
/// start date (lexicographic on ISO strings, matching the TS engine).
List<ScheduledWindow> scheduleGarden(List<Crop> crops, FrostProfile frost) {
  final windows = <ScheduledWindow>[];
  for (final crop in crops) {
    windows.addAll(scheduleCrop(crop, frost));
  }
  // JS Array.sort is stable; Dart's List.sort is not. Tie-break on insertion
  // order so equal start dates keep crop order, matching the TS fixture.
  final indexed = windows.asMap().entries.toList()
    ..sort((a, b) {
      final c = a.value.start.compareTo(b.value.start);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return indexed.map((e) => e.value).toList(growable: false);
}

/// The "this week" view (spec F2): windows whose range overlaps
/// `[today, today + days)`. `today` is passed in, never read from the clock, so
/// it stays pure and testable.
List<ScheduledWindow> windowsActiveInRange(
  List<ScheduledWindow> windows,
  String today, {
  int days = 7,
}) {
  final from = parseIso(today);
  final to = DateTime.fromMillisecondsSinceEpoch(
    from.millisecondsSinceEpoch + days * msPerDay,
    isUtc: true,
  );
  return windows
      .where((w) {
        final ws = parseIso(w.start);
        final we = parseIso(w.end);
        return !we.isBefore(from) && ws.isBefore(to); // overlaps the range
      })
      .toList(growable: false);
}
