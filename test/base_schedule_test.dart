// Base-schedule parity: the Dart engine must reproduce the backend's
// docs/fixtures/base-schedule.fixture.json to the day. We load the SAME crop
// data the app bundles (crops-snapshot.json), run the on-device engine against
// the fixture's frost profile, filter to the sampled crops, and assert an exact
// match — the offline core proven equal to the TS source of truth.

import 'dart:convert';
import 'dart:io';

import 'package:cropsy/timing/crop_snapshot.dart';
import 'package:cropsy/timing/engine.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('base schedule matches the backend fixture day-for-day', () {
    final fixture = jsonDecode(
      File('test/fixtures/base-schedule.fixture.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final snapshot = CropSnapshot.parse(
      File('test/fixtures/crops-snapshot.json').readAsStringSync(),
    );

    final frost = FrostProfile.fromJson(fixture['frost'] as Map<String, dynamic>);
    final expected = (fixture['windows'] as List).cast<Map<String, dynamic>>();

    // The fixture is generated from this sample of crops (verify-engine.ts).
    final sample = expected.map((w) => w['crop_slug'] as String).toSet();

    final produced = scheduleGarden(snapshot.crops, frost)
        .where((w) => sample.contains(w.cropSlug))
        .map((w) => w.toJson())
        .toList();

    // Same count, then field-for-field. Both sides are sorted by start date.
    expect(produced.length, expected.length,
        reason: 'window count differs from fixture');

    for (var i = 0; i < expected.length; i++) {
      final e = expected[i];
      final p = produced[i];
      expect(p['crop_slug'], e['crop_slug'], reason: 'row $i crop_slug');
      expect(p['method'], e['method'], reason: 'row $i method');
      expect(p['start'], e['start'],
          reason: 'row $i start (${e['crop_slug']}/${e['method']})');
      expect(p['end'], e['end'],
          reason: 'row $i end (${e['crop_slug']}/${e['method']})');
      expect(p['min_soil_c'], e['min_soil_c'], reason: 'row $i min_soil_c');
      expect(p['note'], e['note'], reason: 'row $i note');
    }
  });

  test('every bundled crop produces at least one window', () {
    final snapshot = CropSnapshot.parse(
      File('test/fixtures/crops-snapshot.json').readAsStringSync(),
    );
    const frost = FrostProfile(lastFrost: '2026-04-15', firstFrost: '2026-11-01');
    for (final crop in snapshot.crops) {
      expect(scheduleCrop(crop, frost), isNotEmpty,
          reason: '${crop.slug} produced no windows');
    }
  });

  test('windowsActiveInRange overlaps the [today, today+7) range', () {
    const w = ScheduledWindow(
      cropSlug: 'tomato',
      method: MethodType.transplant,
      start: '2026-05-13',
      end: '2026-05-27',
      minSoilC: 12,
      note: null,
    );
    // Overlaps: today inside the window.
    expect(windowsActiveInRange([w], '2026-05-20'), hasLength(1));
    // Ends exactly on `today` → still counts (we >= from).
    expect(windowsActiveInRange([w], '2026-05-27'), hasLength(1));
    // Window entirely in the past (ended before today).
    expect(windowsActiveInRange([w], '2026-05-28'), isEmpty);
    // Range end is exclusive: today+7 == window start → NOT yet active.
    expect(windowsActiveInRange([w], '2026-05-06'), isEmpty); // to = 05-13 == start
    // One day later the range reaches into the window → active.
    expect(windowsActiveInRange([w], '2026-05-07'), hasLength(1)); // to = 05-14
  });
}
