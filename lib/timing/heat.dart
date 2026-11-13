/// Heat trimming: the climate layer on top of the frost-relative windows.
/// Direct port of the backend's `src/timing/heat.ts`; proven equal against
/// `test/fixtures/heat-schedule.fixture.json`.
library;

import 'dates.dart';
import 'types.dart';

const heatLookaheadWeeks = 6;

/// Cold floor for needsClimate (autumn) windows; see `AUTUMN_MIN_C` in heat.ts.
const autumnMinC = 17;

/// needs_climate (autumn) plantings go into heat on purpose and mature into cool weather, so their heat limit is maxC + this.
const autumnHeatAllowanceC = 5;

/// Mean of the weekly maxima over the lookahead that starts in [d]'s week.
double lookaheadMax(List<double> weeklyTmax, DateTime d) {
  final w = weekOfYear(d);
  var sum = 0.0;
  for (var i = 0; i < heatLookaheadWeeks; i++) {
    sum += weeklyTmax[(w + i) % 52];
  }
  return sum / heatLookaheadWeeks;
}

const _outdoor = {
  MethodType.sowDirect,
  MethodType.transplant,
  MethodType.plant,
};

/// First run of days in [w] whose lookahead is at most [maxC] (if set) and at
/// least [minC] (if set); null if none. Indoor sowing, both limits null, or no
/// 52-week climate: [w] unchanged.
// ponytail: first qualifying run only, like the TS engine.
ScheduledWindow? trimForHeat(
  ScheduledWindow w,
  num? maxC,
  List<double>? weeklyTmax, [
  num? minC,
]) {
  if (!_outdoor.contains(w.method) ||
      weeklyTmax == null ||
      weeklyTmax.length != 52 ||
      (maxC == null && minC == null)) {
    return w;
  }
  final end = parseIso(w.end);
  DateTime? runStart;
  DateTime? runEnd;
  for (var d = parseIso(w.start); !d.isAfter(end); d = addDays(d, 1)) {
    final t = lookaheadMax(weeklyTmax, d);
    if ((maxC == null || t <= maxC) && (minC == null || t >= minC)) {
      runStart ??= d;
      runEnd = d;
    } else if (runStart != null) {
      break;
    }
  }
  if (runStart == null || runEnd == null) return null;
  return ScheduledWindow(
    cropSlug: w.cropSlug,
    method: w.method,
    start: toIso(runStart),
    end: toIso(runEnd),
    minSoilC: w.minSoilC,
    note: w.note,
  );
}
