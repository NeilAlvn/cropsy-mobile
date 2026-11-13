import 'dart:convert';
import 'dart:io';

import 'package:cropsy/timing/crop_snapshot.dart';
import 'package:cropsy/timing/season.dart';
import 'package:cropsy/timing/types.dart';
import 'package:cropsy/l10n/region.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'backend_sides.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  test('season path matches the backend fixture', () {
    final fixture = jsonDecode(File('test/fixtures/season.fixture.json').readAsStringSync()) as Map<String, dynamic>;
    final snapshot = CropSnapshot.parse(File('test/fixtures/crops-snapshot.json').readAsStringSync());
    final plants = [
      for (final p in (fixture['plants'] as List).cast<Map<String, dynamic>>())
        SeasonPlant(
          plantId: p['plant_id'] as String,
          cropSlug: p['crop_slug'] as String,
          harvestStart: (p['harvest'] as Map<String, dynamic>?)?['start'] as String?,
          harvestEnd: (p['harvest'] as Map<String, dynamic>?)?['end'] as String?,
        ),
    ];
    final params = fixture['params'] as Map<String, dynamic>;
    final nodes = seasonPath(
      plants,
      snapshot.crops,
      FrostProfile.fromJson(fixture['frost'] as Map<String, dynamic>),
      params: SeasonParams(
        minDaysLeftInWindow: (params['minDaysLeftInWindow'] as num).toInt(),
        maxSuggestions: (params['maxSuggestions'] as num).toInt(),
      ),
    );
    // The backend writes ISO dates into succession notes; the app formats them per region.
    Object? noSuccNotes(Object? j) => [
          for (final n in (j as List).cast<Map>())
            if (n['kind'] == 'succession') ({...n}..remove('note')) else n,
        ];
    expect(noSuccNotes(backendSides(nodes.map((n) => n.toJson()).toList())), noSuccNotes(backendSides(fixture['nodes'])));
  });

  test('bed-frees-up note formats dates per region, not ISO', () {
    final fixture = jsonDecode(File('test/fixtures/season.fixture.json').readAsStringSync()) as Map<String, dynamic>;
    final snapshot = CropSnapshot.parse(File('test/fixtures/crops-snapshot.json').readAsStringSync());
    final plants = [
      for (final p in (fixture['plants'] as List).cast<Map<String, dynamic>>())
        SeasonPlant(
          plantId: p['plant_id'] as String,
          cropSlug: p['crop_slug'] as String,
          harvestStart: (p['harvest'] as Map<String, dynamic>?)?['start'] as String?,
          harvestEnd: (p['harvest'] as Map<String, dynamic>?)?['end'] as String?,
        ),
    ];
    List<SeasonNode> run() => seasonPath(plants, snapshot.crops, FrostProfile.fromJson(fixture['frost'] as Map<String, dynamic>));
    final iso = RegExp(r'\d{4}-\d{2}-\d{2}');
    AppRegion.apply(lang: 'en', country: 'US');
    final us = run().firstWhere((n) => n.note != null && n.kind == SeasonNodeKind.succession);
    expect(us.note!.pick('en'), isNot(contains(iso)));
    expect(us.note!.pick('en'), matches(RegExp(r'\(\w{3} \d{1,2}\)')));
    AppRegion.apply(lang: 'nl', country: 'NL');
    final nl = run().firstWhere((n) => n.kind == SeasonNodeKind.succession);
    expect(nl.note!.pick('nl'), isNot(contains(iso)));
    expect(nl.note!.pick('nl'), matches(RegExp(r'\(\d{1,2} \w+\)')));
    AppRegion.apply(lang: 'nl', country: 'NL');
  });
}
