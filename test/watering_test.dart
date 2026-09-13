// Watering-generator parity against docs/fixtures/watering.fixture.json.

import 'dart:convert';
import 'dart:io';

import 'package:cropsy/timing/types.dart';
import 'package:cropsy/timing/watering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/watering.fixture.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
    final input = c['input'] as Map<String, dynamic>;
    test('watering ${input['plantId']} (${input['cropSlug']}, ${input['potLitres']} L)', () {
      final tasks = wateringTasksFor(
        plantId: input['plantId'] as String,
        cropSlug: input['cropSlug'] as String,
        potLitres: (input['potLitres'] as num?)?.toInt(),
        today: input['today'] as String,
        horizonDays: (input['horizonDays'] as num).toInt(),
        cadence: input['cadence'] == null
            ? null
            : WaterCadence.fromJson(input['cadence'] as Map<String, dynamic>),
      );
      expect(tasks.map((t) => t.toJson()).toList(), c['tasks']);
    });
  }
}
