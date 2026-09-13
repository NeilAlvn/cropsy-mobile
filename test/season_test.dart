import 'dart:convert';
import 'dart:io';

import 'package:cropsy/timing/crop_snapshot.dart';
import 'package:cropsy/timing/season.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(nodes.map((n) => n.toJson()).toList(), fixture['nodes']);
  });
}
