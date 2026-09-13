// Timeline-engine parity: buildPath + logNode must reproduce the backend's
// docs/fixtures/replan.fixture.json node-for-node, date-for-date.

import 'dart:convert';
import 'dart:io';

import 'package:cropsy/timing/crop_snapshot.dart';
import 'package:cropsy/timing/replan.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/replan.fixture.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final snapshot = CropSnapshot.parse(
    File('test/fixtures/crops-snapshot.json').readAsStringSync(),
  );

  for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
    test(c['name'] as String, () {
      final crop = snapshot.crops.firstWhere((x) => x.slug == c['crop_slug']);
      final start = c['start'] as Map<String, dynamic>;
      final path = buildPath(
        crop,
        PathStart(method: methodFromWire(start['method'] as String), on: start['on'] as String),
        c['plant_id'] as String,
      );
      expect(path.map((n) => n.toJson()).toList(), c['path']);

      final log = c['log'] as Map<String, dynamic>;
      final result = logNode(
        path,
        log['node_id'] as String,
        log['logged_on'] as String,
        params: ReplanParams.fromJson(c['params'] as Map<String, dynamic>),
      );
      final expected = c['result'] as Map<String, dynamic>;
      expect(result.shiftDays, expected['shift_days']);
      expect(result.nodes.map((n) => n.toJson()).toList(), expected['nodes']);
      expect(result.warnings.map((w) => w.toJson()).toList(), expected['warnings']);
      // Input untouched.
      expect(path.every((n) => n.loggedOn == null && n.movedReason == null), isTrue);
    });
  }
}
