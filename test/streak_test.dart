import 'dart:convert';
import 'dart:io';

import 'package:cropsy/timing/dates.dart';
import 'package:cropsy/timing/streak.dart';
import 'package:flutter_test/flutter_test.dart';

/// [days] consecutive active days starting on [from].
List<String> _run(String from, int days) =>
    [for (var i = 0; i < days; i++) toIso(addDays(parseIso(from), i))];

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

  // ── milestones, for the season path ───────────────────────────────────────

  test('a milestone is dated the day the run reached it', () {
    final marks = streakMilestones(_run('2026-03-01', 40), '2026-04-09');
    expect(marks, [
      (days: 7, on: '2026-03-07'),
      (days: 30, on: '2026-03-30'),
    ]);
  });

  test('a freeze day carries the run over the threshold', () {
    // Six days, a missed day the free freeze bridges, then the seventh.
    final active = [..._run('2026-03-01', 6), '2026-03-08'];
    expect(streakMilestones(active, '2026-03-08'),
        [(days: 7, on: '2026-03-08')]);
    // The count on Home agrees, which is the whole point of reusing it.
    expect(computeStreak(active, '2026-03-08').count, 7);
    // Without a freeze to spend, the run broke and the week never happened.
    expect(
      streakMilestones(active, '2026-03-08',
          params: const StreakParams(freezesPerMonth: 0)),
      isEmpty,
    );
  });

  test('a milestone never lands on a day the gardener sat out', () {
    // The run is long enough on the freeze day itself; the stop waits for the
    // next day they actually did something.
    final active = [..._run('2026-03-01', 7), '2026-03-09'];
    final marks = streakMilestones(active, '2026-03-09');
    expect(marks.single.on, '2026-03-07');
    expect(active, contains(marks.single.on));
  });

  test('a run that never gets there, and a year that never started', () {
    expect(streakMilestones(_run('2026-03-01', 6), '2026-03-06'), isEmpty);
    expect(streakMilestones(const [], '2026-03-06'), isEmpty);
  });
}
