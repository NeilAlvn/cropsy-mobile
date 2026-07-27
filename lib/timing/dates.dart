/// Tiny UTC-calendar date helpers shared by the timing engines. Dates are
/// treated as UTC calendar days so timezone drift can never shift a window by a
/// day. This is a direct port of the backend's `src/timing/dates.ts` — the two
/// must agree to the day (see docs/API-CONTRACT.md §4).
library;

const int msPerDay = 86400000;

/// Parse an ISO `yyyy-mm-dd` string into a UTC-midnight [DateTime].
DateTime parseIso(String d) {
  final parts = d.split('-');
  if (parts.length != 3) {
    throw ArgumentError('invalid ISO date: $d');
  }
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final day = int.parse(parts[2]);
  return DateTime.utc(y, m, day);
}

/// Format a UTC [DateTime] back to `yyyy-mm-dd`.
String toIso(DateTime d) => d.toIso8601String().substring(0, 10);

/// Add [n] calendar days (rounded, matching the TS `Math.round`).
DateTime addDays(DateTime d, num n) =>
    DateTime.fromMillisecondsSinceEpoch(
      d.millisecondsSinceEpoch + n.round() * msPerDay,
      isUtc: true,
    );

/// Add [weeks] (fractional allowed; rounded to whole days like the TS engine).
DateTime addWeeks(DateTime d, num weeks) => addDays(d, (weeks * 7).round());
