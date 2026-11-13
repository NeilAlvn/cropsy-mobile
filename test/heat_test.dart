import 'package:cropsy/timing/dates.dart';
import 'package:cropsy/timing/heat.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

final hot = List<double>.generate(52, (w) => w >= 18 && w <= 38 ? 34.0 : 20.0);
// Weeks >= 37 are 14 C, earlier 20 (mirrors COLD_AUTUMN in verify-heat.ts).
final coldAutumn = List<double>.generate(52, (w) => w >= 37 ? 14.0 : 20.0);

ScheduledWindow win(
  String start,
  String end, [
  MethodType m = MethodType.sowDirect,
]) => ScheduledWindow(
  cropSlug: 'x',
  method: m,
  start: start,
  end: end,
  minSoilC: null,
  note: null,
);

void main() {
  test('weekOfYear folds the last days into 51', () {
    expect(weekOfYear(DateTime.utc(2026, 1, 1)), 0);
    expect(weekOfYear(DateTime.utc(2024, 12, 31)), 51);
  });

  test('same answers as the backend verify-heat script', () {
    expect(autumnMinC, 17);
    final coldFloor = trimForHeat(
      win('2026-09-01', '2026-10-31'),
      null,
      coldAutumn,
      autumnMinC,
    )!;
    expect([coldFloor.start, coldFloor.end], ['2026-09-01', '2026-09-02']);
    final both = trimForHeat(
      win('2026-09-01', '2026-10-31'),
      26,
      hot,
      autumnMinC,
    )!;
    expect([both.start, both.end], ['2026-09-17', '2026-10-31']);
    expect(trimForHeat(win('2026-03-01', '2026-03-31'), 26, hot, 21), isNull);
    expect(
      lookaheadMax(hot, DateTime.utc(2026, 4, 9)),
      closeTo((2 * 34 + 4 * 20) / 6, 1e-9),
    );
    final spring = trimForHeat(win('2026-03-01', '2026-06-30'), 26, hot)!;
    expect([spring.start, spring.end], ['2026-03-01', '2026-04-15']);
    expect(trimForHeat(win('2026-06-01', '2026-07-31'), 26, hot), isNull);
    final autumn = trimForHeat(win('2026-09-01', '2026-10-31'), 26, hot)!;
    expect([autumn.start, autumn.end], ['2026-09-17', '2026-10-31']);
    final tolerant = trimForHeat(win('2026-06-01', '2026-07-31'), 35, hot)!;
    expect([tolerant.start, tolerant.end], ['2026-06-01', '2026-07-31']);
    expect(
      trimForHeat(
        win('2026-06-01', '2026-07-31', MethodType.sowIndoor),
        26,
        hot,
      )!.start,
      '2026-06-01',
    );
    expect(
      trimForHeat(win('2026-06-01', '2026-07-31'), null, hot)!.end,
      '2026-07-31',
    );
    expect(
      trimForHeat(win('2026-06-01', '2026-07-31'), 26, null)!.end,
      '2026-07-31',
    );
  });

  test(
    'autumn allowance: max_c 27 drops the 15-29 Sep window, 27 + 5 keeps it',
    () {
      // Weeks 30-41 at 31 C (mirrors ALLOW in verify-engine.ts): lookaheads of
      // weeks 36/37/38 are 31, 29.17, 27.33 - all above 27, all within 32.
      final allow = List<double>.generate(
        52,
        (w) => w >= 30 && w <= 41 ? 31.0 : 20.0,
      );
      final w = win('2026-09-15', '2026-09-29', MethodType.transplant);
      expect(autumnHeatAllowanceC, 5);
      expect(trimForHeat(w, 27, allow, autumnMinC), isNull);
      final kept = trimForHeat(
        w,
        27 + autumnHeatAllowanceC,
        allow,
        autumnMinC,
      )!;
      expect([kept.start, kept.end], ['2026-09-15', '2026-09-29']);
    },
  );

  test('FrostProfile carries weekly_tmax through json and forSeason', () {
    final p = FrostProfile.fromJson({
      'last_frost': '2026-02-18',
      'first_frost': '2026-12-08',
      'weekly_tmax': hot,
    });
    expect(p.weeklyTmax!.length, 52);
    expect(FrostProfile.fromJson(p.toJson()).weeklyTmax![20], 34);
    expect(p.forSeason('2027-03-01').weeklyTmax![20], 34);
    expect(
      FrostProfile.fromJson({
        'last_frost': '2026-04-15',
        'first_frost': '2026-11-01',
      }).weeklyTmax,
      isNull,
    );
  });
}
