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

  for (var guard = 0; guard < 3660; guard++) {
    final iso = toIso(day);
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
