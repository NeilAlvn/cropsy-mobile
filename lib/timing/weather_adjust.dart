/// Weather-adjustment engine — the ONLINE overlay (API contract §5, spec F4).
///
/// The base schedule (`engine.dart`) is deterministic and runs offline. This
/// layer nudges individual *tasks* using live weather so reminders stop being
/// dumb:
///   • a watering task is SKIPPED when it has rained / will rain (soil is wet)
///   • a watering task is BROUGHT FORWARD to meet a hot, dry day before it
///   • a sow/transplant task is DEFERRED while the soil is still too cold
/// It returns deltas only; the caller applies them on top of the base schedule.
/// Offline, none of this runs and the base schedule stands — never blank.
///
/// Direct port of the backend `src/timing/weather-adjust.ts`, kept pure and
/// clock-free so the same rules can run on-device and stay fixture-reproducible.
library;

import 'dates.dart';
import 'types.dart';

/// `pot_on` and `thin` are container-gardening actions. Neither is
/// weather-adjusted today; they exist so the client can express them and so
/// adding them later needs no migration on either side. Unknown kinds fall
/// through to [AdjustAction.none], so a new kind can never fabricate a change.
enum TaskKind { water, sow, transplant, harvest, feed, potOn, thin }

const _kindFromWire = <String, TaskKind>{
  'water': TaskKind.water,
  'sow': TaskKind.sow,
  'transplant': TaskKind.transplant,
  'harvest': TaskKind.harvest,
  'feed': TaskKind.feed,
  'pot_on': TaskKind.potOn,
  'thin': TaskKind.thin,
};
const _kindToWire = <TaskKind, String>{
  TaskKind.water: 'water',
  TaskKind.sow: 'sow',
  TaskKind.transplant: 'transplant',
  TaskKind.harvest: 'harvest',
  TaskKind.feed: 'feed',
  TaskKind.potOn: 'pot_on',
  TaskKind.thin: 'thin',
};

TaskKind taskKindFromWire(String s) {
  final k = _kindFromWire[s];
  if (k == null) throw ArgumentError('unknown task kind: $s');
  return k;
}

String taskKindToWire(TaskKind k) => _kindToWire[k]!;

class Task {
  const Task({
    required this.id,
    required this.cropSlug,
    required this.kind,
    required this.due,
    this.minSoilC,
  });

  final String id;
  final String cropSlug;
  final TaskKind kind;

  /// ISO `yyyy-mm-dd` the base schedule wants this done.
  final String due;

  /// Soil-temp gate carried from the crop method (sow/transplant only).
  final num? minSoilC;

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        cropSlug: j['crop_slug'] as String,
        kind: taskKindFromWire(j['kind'] as String),
        due: j['due'] as String,
        minSoilC: j['min_soil_c'] as num?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_slug': cropSlug,
        'kind': taskKindToWire(kind),
        'due': due,
        if (minSoilC != null) 'min_soil_c': minSoilC,
      };
}

/// One day of weather. Soil temp is proxied by air (mean of min/max).
class DayObservation {
  const DayObservation({
    required this.date,
    required this.precipMm,
    required this.tempMinC,
    required this.tempMaxC,
  });

  final String date;
  final num precipMm;
  final num tempMinC;
  final num tempMaxC;

  factory DayObservation.fromJson(Map<String, dynamic> j) => DayObservation(
        date: j['date'] as String,
        precipMm: j['precip_mm'] as num,
        tempMinC: j['temp_min_c'] as num,
        tempMaxC: j['temp_max_c'] as num,
      );

  num get meanTemp => (tempMinC + tempMaxC) / 2;
}

enum AdjustAction { skip, defer, bringForward, none }

const _actionToWire = <AdjustAction, String>{
  AdjustAction.skip: 'skip',
  AdjustAction.defer: 'defer',
  AdjustAction.bringForward: 'bring_forward',
  AdjustAction.none: 'none',
};

String adjustActionToWire(AdjustAction a) => _actionToWire[a]!;

class Adjustment {
  const Adjustment({
    required this.taskId,
    required this.action,
    this.to,
    required this.reason,
  });

  final String taskId;
  final AdjustAction action;

  /// New date for defer / bring_forward. Absent for skip / none.
  final String? to;
  final LocalizedText reason;

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'action': adjustActionToWire(action),
        if (to != null) 'to': to,
        'reason': reason.toJson(),
      };
}

class AdjustParams {
  const AdjustParams({
    required this.rainLookbackDays,
    required this.rainForecastDays,
    required this.wetThresholdMm,
    required this.maxDeferDays,
    required this.heatThresholdC,
    required this.heatLookbackDays,
    required this.heatDryMaxMm,
    required this.today,
  });

  /// Days before `due` to count as recent rain.
  final int rainLookbackDays;

  /// Days after `due` whose forecast rain also counts (imminent rain).
  final int rainForecastDays;

  /// Cumulative rain over that window (mm) at/above which watering is skipped.
  final num wetThresholdMm;

  /// Furthest a task may be deferred before we give up and keep the base date.
  final int maxDeferDays;

  /// Daily max at/above which a container plant needs water sooner (°C).
  final num heatThresholdC;

  /// How far before `due` we'll pull a watering forward to meet a hot day.
  final int heatLookbackDays;

  /// A hot day only counts if it's also dry — rain at/above this cancels it.
  final num heatDryMaxMm;

  /// Today (ISO `yyyy-mm-dd`), so a task is never brought forward into the past.
  /// Injected rather than read from a clock. `null` disables the clamp.
  final String? today;
}

/// 30 degrees C is where containers start drying out within a day — the whole
/// premise of this app. A raised bed buffers heat far better than a 10-litre
/// balcony pot, so the threshold is deliberately not a field-grower's number.
extension AdjustParamsCopy on AdjustParams {
  /// Same rules, a different clock — the repository stamps `today`.
  AdjustParams withToday(String? today) => AdjustParams(
        rainLookbackDays: rainLookbackDays,
        rainForecastDays: rainForecastDays,
        wetThresholdMm: wetThresholdMm,
        maxDeferDays: maxDeferDays,
        heatThresholdC: heatThresholdC,
        heatLookbackDays: heatLookbackDays,
        heatDryMaxMm: heatDryMaxMm,
        today: today,
      );
}

const AdjustParams defaultAdjust = AdjustParams(
  rainLookbackDays: 2,
  rainForecastDays: 1,
  wetThresholdMm: 10,
  maxDeferDays: 14,
  heatThresholdC: 30,
  heatLookbackDays: 3,
  heatDryMaxMm: 2,
  today: null,
);

Adjustment _none(Task task) => Adjustment(
      taskId: task.id,
      action: AdjustAction.none,
      reason: const LocalizedText(nl: '', en: ''),
    );

Adjustment _adjustTask(
  Task task,
  Map<String, DayObservation> byDate,
  AdjustParams p,
) {
  final due = parseIso(task.due);

  if (task.kind == TaskKind.water) {
    // Sum rain across [due - lookback, due + forecast]. Enough means soil's wet.
    num rain = 0;
    var haveData = false;
    for (var d = -p.rainLookbackDays; d <= p.rainForecastDays; d++) {
      final obs = byDate[toIso(addDays(due, d))];
      if (obs != null) {
        rain += obs.precipMm;
        haveData = true;
      }
    }
    if (!haveData) return _none(task);
    if (rain >= p.wetThresholdMm) {
      final mm = rain.round();
      return Adjustment(
        taskId: task.id,
        action: AdjustAction.skip,
        reason: LocalizedText(
          nl: 'Genoeg regen rond deze dag ($mm mm) — overslaan.',
          en: 'Enough rain around this day ($mm mm) — skip watering.',
        ),
      );
    }

    // Not wet. Is there a hot, dry day before the watering is due? A container
    // can go from damp to bone dry inside one hot afternoon, so pull the
    // watering forward to the first hot day. Wet always wins over hot.
    for (var d = -p.heatLookbackDays; d < 0; d++) {
      final day = toIso(addDays(due, d));
      final obs = byDate[day];
      if (obs == null) continue;
      if (obs.tempMaxC < p.heatThresholdC) continue;
      if (obs.precipMm > p.heatDryMaxMm) continue;
      // Never schedule into the past. `today` is injected, not read from a clock.
      if (p.today != null && day.compareTo(p.today!) < 0) continue;
      final t = obs.tempMaxC.round();
      return Adjustment(
        taskId: task.id,
        action: AdjustAction.bringForward,
        to: day,
        reason: LocalizedText(
          nl: 'Hitte verwacht ($t°C) — eerder water geven.',
          en: 'Heat expected ($t°C) — water earlier.',
        ),
      );
    }
    return _none(task);
  }

  if (task.kind == TaskKind.sow || task.kind == TaskKind.transplant) {
    final gate = task.minSoilC;
    if (gate == null) return _none(task);
    final dueObs = byDate[task.due];
    if (dueObs == null) return _none(task);
    // Warm enough already, leave it.
    if (dueObs.meanTemp >= gate) return _none(task);
    // Too cold: find the first upcoming day within maxDefer that's warm enough.
    for (var d = 1; d <= p.maxDeferDays; d++) {
      final obs = byDate[toIso(addDays(due, d))];
      if (obs != null && obs.meanTemp >= gate) {
        return Adjustment(
          taskId: task.id,
          action: AdjustAction.defer,
          to: obs.date,
          reason: LocalizedText(
            nl: 'Bodem nog te koud (< $gate°C) — uitgesteld tot het warmer is.',
            en: 'Soil still too cold (< $gate°C) — held until it warms up.',
          ),
        );
      }
    }
    // Stays cold across the whole window: flag it, but don't invent a date.
    return Adjustment(
      taskId: task.id,
      action: AdjustAction.defer,
      to: toIso(addDays(due, p.maxDeferDays)),
      reason: LocalizedText(
        nl: 'Bodem blijft te koud (< $gate°C) — nog even wachten.',
        en: 'Soil staying too cold (< $gate°C) — wait a little longer.',
      ),
    );
  }

  // harvest / feed / pot_on / thin: not weather-adjusted. Unknown kinds fall
  // through to `none` by construction, so adding a kind can never fabricate an
  // adjustment — new kinds are safe to introduce from either side.
  return _none(task);
}

/// Adjust a batch of tasks. Only tasks that actually changed are returned,
/// matching the contract's "deltas only" — an empty result means keep the base
/// schedule.
List<Adjustment> adjustTasks(
  List<Task> tasks,
  List<DayObservation> observations, {
  AdjustParams params = defaultAdjust,
}) {
  final byDate = {for (final o in observations) o.date: o};
  return tasks
      .map((t) => _adjustTask(t, byDate, params))
      .where((a) => a.action != AdjustAction.none)
      .toList(growable: false);
}
