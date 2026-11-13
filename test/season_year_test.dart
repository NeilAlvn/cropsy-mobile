import 'package:cropsy/timing/season_year.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('north season is the calendar year', () {
    expect(seasonYearOf('2026-11-13', south: false), 2026);
    expect(isoForSeason('10-25', 2026, south: false), '2026-10-25');
  });

  test('south season runs July to June', () {
    expect(seasonYearOf('2027-03-01', south: true), 2026);
    expect(seasonYearOf('2026-07-01', south: true), 2026);
    expect(isoForSeason('09-20', 2026, south: true), '2026-09-20');
    expect(isoForSeason('05-05', 2026, south: true), '2027-05-05');
    expect(seasonStart(2026, south: true), DateTime.utc(2026, 7, 1));
    expect(
      [for (var i = 0; i < 12; i++) monthAt(i, south: true)],
      [7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6],
    );
  });

  test('forSeason keeps NL presets as they were', () {
    const p = FrostProfile(lastFrost: '2026-04-15', firstFrost: '2026-11-01');
    final s = p.forSeason('2027-02-01');
    expect(s.lastFrost, '2027-04-15');
    expect(s.firstFrost, '2027-11-01');
  });

  test(
    'forSeason in Melbourne in March picks the season that started last July',
    () {
      const p = FrostProfile(
        lastFrost: '2026-09-20',
        firstFrost: '2027-05-05',
        south: true,
      );
      final s = p.forSeason('2028-03-01');
      expect(s.lastFrost, '2027-09-20');
      expect(s.firstFrost, '2028-05-05');
      expect(s.south, isTrue);
    },
  );

  test('fromJson and toJson carry hemisphere and regime', () {
    final p = FrostProfile.fromJson({
      'last_frost': '2026-09-20',
      'first_frost': '2027-05-05',
      'hemisphere': 'south',
      'regime': 'frost_free',
    });
    expect(p.south, isTrue);
    expect(p.regime, 'frost_free');
    expect(FrostProfile.fromJson(p.toJson()).firstFrost, '2027-05-05');
    expect(
      FrostProfile.fromJson({
        'last_frost': '2026-04-15',
        'first_frost': '2026-11-01',
      }).south,
      isFalse,
    );
  });
}
