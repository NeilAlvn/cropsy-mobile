// Heat parity: the Dart engine must reproduce the backend's
// docs/fixtures/heat-schedule.fixture.json (and climate-rules.fixture.json) to the day. We load the SAME crop
// data the app bundles (crops-snapshot.json), run the on-device engine against
// the fixture's frost profile, filter to the sampled crops, and assert an exact
// match — the offline core proven equal to the TS source of truth.

import 'dart:convert';
import 'dart:io';

import 'package:cropsy/timing/crop_snapshot.dart';
import 'package:cropsy/timing/engine.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backend_sides.dart';

void main() {
  test('heat schedule matches the backend fixture day-for-day', () {
    final fixture =
        jsonDecode(
              File(
                'test/fixtures/heat-schedule.fixture.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final snapshot = CropSnapshot.parse(
      File('test/fixtures/crops-snapshot.json').readAsStringSync(),
    );

    final frost = FrostProfile.fromJson(
      fixture['frost'] as Map<String, dynamic>,
    );
    final expected = (fixture['windows'] as List).cast<Map<String, dynamic>>();

    // The fixture is generated from this sample of crops (verify-engine.ts).
    final sample = expected.map((w) => w['crop_slug'] as String).toSet();

    final produced = scheduleGarden(
      snapshot.crops,
      frost,
    ).where((w) => sample.contains(w.cropSlug)).map((w) => w.toJson()).toList();

    // Same count, then field-for-field. Both sides are sorted by start date.
    expect(
      produced.length,
      expected.length,
      reason: 'window count differs from fixture',
    );

    for (var i = 0; i < expected.length; i++) {
      final e = expected[i];
      final p = produced[i];
      expect(p['crop_slug'], e['crop_slug'], reason: 'row $i crop_slug');
      expect(p['method'], e['method'], reason: 'row $i method');
      expect(
        p['start'],
        e['start'],
        reason: 'row $i start (${e['crop_slug']}/${e['method']})',
      );
      expect(
        p['end'],
        e['end'],
        reason: 'row $i end (${e['crop_slug']}/${e['method']})',
      );
      expect(p['min_soil_c'], e['min_soil_c'], reason: 'row $i min_soil_c');
      expect(
        backendSides(p['note']),
        backendSides(e['note']),
        reason: 'row $i note',
      );
    }
  });

  test('climate rules match the backend fixture day-for-day', () {
    final fixture =
        jsonDecode(
              File(
                'test/fixtures/climate-rules.fixture.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final snapshot = CropSnapshot.parse(
      File('test/fixtures/crops-snapshot.json').readAsStringSync(),
    );
    for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
      final name = c['name'];
      final frost = FrostProfile.fromJson(c['frost'] as Map<String, dynamic>);
      final expected = (c['windows'] as List).cast<Map<String, dynamic>>();
      // Crops in the order the backend scheduled them (first appearance).
      final slugs = expected
          .map((w) => w['crop_slug'] as String)
          .toSet()
          .toList();
      final crops = [
        for (final slug in slugs)
          snapshot.crops.firstWhere((cr) => cr.slug == slug),
      ];
      final produced = [
        for (final cr in crops) ...scheduleCrop(cr, frost),
      ].map((w) => w.toJson()).toList();
      expect(produced.length, expected.length, reason: '$name: window count');
      for (var i = 0; i < expected.length; i++) {
        final e = expected[i];
        final p = produced[i];
        final at = '$name row $i (${e['crop_slug']}/${e['method']})';
        expect(p['crop_slug'], e['crop_slug'], reason: '$at crop_slug');
        expect(p['method'], e['method'], reason: '$at method');
        expect(p['start'], e['start'], reason: '$at start');
        expect(p['end'], e['end'], reason: '$at end');
        expect(p['min_soil_c'], e['min_soil_c'], reason: '$at min_soil_c');
        expect(
          backendSides(p['note']),
          backendSides(e['note']),
          reason: '$at note',
        );
      }
    }
  });
}
