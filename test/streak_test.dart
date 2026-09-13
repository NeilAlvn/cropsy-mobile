import 'dart:convert';
import 'dart:io';

import 'package:cropsy/timing/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = jsonDecode(File('test/fixtures/streak.fixture.json').readAsStringSync()) as Map<String, dynamic>;
  for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
    test(c['name'] as String, () {
      final p = c['params'] as Map<String, dynamic>;
      final r = computeStreak(
        (c['active'] as List).cast<String>(),
        c['today'] as String,
        params: StreakParams(
          freezesPerMonth: (p['freezesPerMonth'] as num?)?.toInt(),
          pausedMonths: (p['pausedMonths'] as List).cast<int>(),
        ),
      );
      expect(r.toJson(), c['result']);
    });
  }
}
