// Weather-adjust parity: the Dart overlay must reproduce the backend's
// docs/fixtures/weather-adjust.fixture.json exactly — same actions, same target
// dates, same localized reason strings. This is the online layer; proving it
// here means an on-device hint from cached weather agrees with the server.

import 'dart:convert';
import 'dart:io';

import 'package:cropsy/timing/weather_adjust.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weather adjustments match the backend fixture exactly', () {
    final fixture = jsonDecode(
      File('test/fixtures/weather-adjust.fixture.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final observations = (fixture['observations'] as List)
        .map((o) => DayObservation.fromJson(o as Map<String, dynamic>))
        .toList();
    final tasks = (fixture['tasks'] as List)
        .map((t) => Task.fromJson(t as Map<String, dynamic>))
        .toList();
    final expected = (fixture['adjustments'] as List).cast<Map<String, dynamic>>();

    // Fixture uses DEFAULT_ADJUST with today = null (no past-clamp).
    final produced = adjustTasks(tasks, observations).map((a) => a.toJson()).toList();

    expect(produced.length, expected.length,
        reason: 'adjustment count differs from fixture');

    for (var i = 0; i < expected.length; i++) {
      final e = expected[i];
      final p = produced[i];
      expect(p['task_id'], e['task_id'], reason: 'row $i task_id');
      expect(p['action'], e['action'], reason: 'row $i action (${e['task_id']})');
      expect(p['to'], e['to'], reason: 'row $i to (${e['task_id']})');
      expect(p['reason'], e['reason'], reason: 'row $i reason (${e['task_id']})');
    }
  });

  test('deltas only: harvest / pot_on / thin never produce an adjustment', () {
    final observations = (jsonDecode(
      File('test/fixtures/weather-adjust.fixture.json').readAsStringSync(),
    ) as Map<String, dynamic>)['observations'] as List;
    final obs = observations
        .map((o) => DayObservation.fromJson(o as Map<String, dynamic>))
        .toList();

    const inert = [TaskKind.harvest, TaskKind.feed, TaskKind.potOn, TaskKind.thin];
    for (final kind in inert) {
      final result = adjustTasks(
        [Task(id: 'x', cropSlug: 'tomato', kind: kind, due: '2026-05-12')],
        obs,
      );
      expect(result, isEmpty,
          reason: '${taskKindToWire(kind)} should never be adjusted');
    }
  });

  test('the today clamp keeps a bring_forward from landing in the past', () {
    final observations = (jsonDecode(
      File('test/fixtures/weather-adjust.fixture.json').readAsStringSync(),
    ) as Map<String, dynamic>)['observations'] as List;
    final obs = observations
        .map((o) => DayObservation.fromJson(o as Map<String, dynamic>))
        .toList();

    // t-water-heat (due 05-12) normally brings forward to the hot day 05-10.
    final task = [
      const Task(id: 't-water-heat', cropSlug: 'tomato', kind: TaskKind.water, due: '2026-05-12'),
    ];

    // today == due (05-12): every hot day in the 3-day lookback (05-09..05-11)
    // is now in the past, so the clamp forbids all of them → no adjustment.
    const clamped = AdjustParams(
      rainLookbackDays: 2,
      rainForecastDays: 1,
      wetThresholdMm: 10,
      maxDeferDays: 14,
      heatThresholdC: 30,
      heatLookbackDays: 3,
      heatDryMaxMm: 2,
      today: '2026-05-12',
    );
    expect(adjustTasks(task, obs, params: clamped), isEmpty);

    // With no clamp (default) it still brings forward to 05-10.
    final unclamped = adjustTasks(task, obs);
    expect(unclamped, hasLength(1));
    expect(unclamped.first.to, '2026-05-10');
  });
}
