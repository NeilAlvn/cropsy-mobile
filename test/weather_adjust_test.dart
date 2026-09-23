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

  test('WMO codes group at their boundaries, and nowhere else', () {
    // First and last code of every published band, so a shifted edge fails.
    const expected = <int, WeatherCondition>{
      0: WeatherCondition.clear,
      1: WeatherCondition.partlyCloudy,
      2: WeatherCondition.partlyCloudy,
      3: WeatherCondition.overcast,
      45: WeatherCondition.fog,
      48: WeatherCondition.fog,
      51: WeatherCondition.drizzle,
      57: WeatherCondition.drizzle,
      61: WeatherCondition.rain,
      67: WeatherCondition.rain,
      71: WeatherCondition.snow,
      77: WeatherCondition.snow,
      80: WeatherCondition.rain,
      82: WeatherCondition.rain,
      85: WeatherCondition.snow,
      86: WeatherCondition.snow,
      95: WeatherCondition.thunder,
      96: WeatherCondition.thunder,
      99: WeatherCondition.thunder,
    };
    expected.forEach((code, condition) {
      expect(weatherConditionFor(code), condition, reason: 'code $code');
    });

    // Gaps between the bands, and a code past the end of the table: unknown,
    // never the neighbouring band — the card would rather say nothing.
    for (final code in [4, 44, 49, 50, 58, 60, 68, 70, 78, 79, 83, 87, 94, 97, 100, -1]) {
      expect(weatherConditionFor(code), isNull, reason: 'code $code');
    }
    expect(weatherConditionFor(null), isNull);
  });

  test('DayObservation.fromJson parses a cache written before weather_code', () {
    final old = DayObservation.fromJson(const {
      'date': '2026-05-12',
      'precip_mm': 3,
      'temp_min_c': 8,
      'temp_max_c': 19,
    });
    expect(old.weatherCode, isNull);
    expect(old.precipMm, 3);
    expect(old.meanTemp, 13.5);

    expect(
      DayObservation.fromJson(const {
        'date': '2026-05-12',
        'precip_mm': 3,
        'temp_min_c': 8,
        'temp_max_c': 19,
        'weather_code': 61,
      }).weatherCode,
      61,
    );
  });
}
