import 'package:cropsy/l10n/date_fmt.dart';
import 'package:cropsy/l10n/region.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  tearDown(() => AppRegion.apply(lang: 'nl', country: 'NL'));
  final d = DateTime(2026, 5, 3, 15, 5); // a Sunday

  test('US month-first, UK day-first, NL unchanged', () {
    AppRegion.apply(lang: 'en', country: 'US');
    expect(dayMonth(d), 'May 3');
    expect(weekdayDayMonth(d), 'Sunday May 3');
    expect(dayMonthYear(d), 'May 3, 2026');
    expect(clock(d), allOf(contains('3:05'), contains('PM')));
    expect(dayMonthIso('2026-05-14'), 'May 14');
    AppRegion.apply(lang: 'en', country: 'GB');
    expect(dayMonth(d), '3 May');
    expect(weekdayDayMonth(d), 'Sunday 3 May');
    expect(clock(d), '15:05');
    AppRegion.apply(lang: 'nl', country: 'NL');
    expect(dayMonth(d), '3 mei');
    expect(weekdayDayMonth(d), 'zondag 3 mei');
    expect(clock(d), '15:05');
  });

  test('season label', () {
    expect(seasonLabel('2026-11-13', south: false), '2026');
    expect(seasonLabel('2026-11-13', south: true), '2026/27');
    expect(seasonLabel('2027-03-01', south: true), '2026/27');
  });
}
