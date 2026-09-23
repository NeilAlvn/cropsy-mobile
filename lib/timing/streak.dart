/// Streaks (PRD §7.3): consecutive days with at least one task completed OR
/// explicitly skipped with a reason (rain counts). Freeze days cover a gap:
/// 2 per calendar month free, unlimited premium. No XP, no leagues (§7.5).
///
/// Port of `src/timing/streak.ts`; parity in `test/streak_test.dart`.
library;

import 'dates.dart';

class StreakParams {
  const StreakParams({this.freezesPerMonth = 2, this.pausedMonths = const []});

  /// Freeze days available per calendar month; null = unlimited (premium).
  final int? freezesPerMonth;

  /// Winter pause: months (1–12) in which a gap never breaks the streak.
  final List<int> pausedMonths;
}

const defaultStreak = StreakParams();

class StreakResult {
  const StreakResult({required this.count, required this.freezesUsed, required this.todayOpen});

  /// Consecutive-day count ending today (today counts only if active).
  final int count;

  /// Freeze days spent, keyed by yyyy-mm.
  final Map<String, int> freezesUsed;

  /// True when today is not yet active — at risk until it is.
  final bool todayOpen;

  Map<String, dynamic> toJson() => {'count': count, 'freezesUsed': freezesUsed, 'todayOpen': todayOpen};
}

StreakResult computeStreak(Iterable<String> activeDays, String today, {StreakParams params = defaultStreak}) {
  final active = activeDays.toSet();
  final freezesUsed = <String, int>{};
  var count = 0;
  var day = parseIso(today);
  final todayOpen = !active.contains(today);
  if (todayOpen) day = addDays(day, -1);
  // Freezes bridge gaps between active days; never spent before the first.
  String? earliest;
  for (final d in active) {
    if (earliest == null || d.compareTo(earliest) < 0) earliest = d;
  }

  for (var guard = 0; guard < 3660; guard++) {
    final iso = toIso(day);
    if (earliest == null || iso.compareTo(earliest) < 0) break;
    if (active.contains(iso)) {
      count++;
    } else if (params.pausedMonths.contains(day.month)) {
      // paused: bridged for free, counts nothing
    } else {
      final m = iso.substring(0, 7);
      final used = freezesUsed[m] ?? 0;
      final cap = params.freezesPerMonth;
      if (cap != null && used >= cap) break;
      freezesUsed[m] = used + 1;
    }
    day = addDays(day, -1);
  }
  return StreakResult(count: count, freezesUsed: freezesUsed, todayOpen: todayOpen);
}

/// The runs worth marking on the season path: a week, a month, a hundred days.
const streakMilestoneDays = [7, 30, 100];

/// The day each milestone in [streakMilestoneDays] was reached, oldest first.
///
/// The dating has to agree with the number on Home to the day, freeze days and
/// winter pause included, so it asks [computeStreak] rather than re-deriving
/// runs of its own: for every active day, the run ending there, and the first
/// day that run is long enough is the milestone. Only active days are
/// candidates — a freeze bridges a gap, it is not a day the gardener showed up,
/// so it can carry a run over a threshold but never be the day it happened.
///
/// ponytail: O(days²) — a year of daily gardening is ~365 runs of ~365 steps,
/// microseconds, and it is recomputed once per path build. If this ever spans
/// many years, walk the days once and carry the run forward instead.
List<({int days, String on})> streakMilestones(
  Iterable<String> activeDays,
  String today, {
  StreakParams params = defaultStreak,
}) {
  final days = activeDays.where((d) => d.compareTo(today) <= 0).toList()..sort();
  final out = <({int days, String on})>[];
  var next = 0;
  for (final day in days) {
    if (next >= streakMilestoneDays.length) break;
    final run = computeStreak(activeDays, day, params: params).count;
    // One active day can clear more than one threshold only if the thresholds
    // were miles apart; the while keeps that honest rather than assuming.
    while (next < streakMilestoneDays.length && run >= streakMilestoneDays[next]) {
      out.add((days: streakMilestoneDays[next], on: day));
      next++;
    }
  }
  return out;
}
