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

  test('non-English keeps its fixed patterns', () {
    AppRegion.apply(lang: 'de', country: 'DE');
    expect(dayMonth(d), '3 Mai');
    expect(weekdayDayMonth(d), 'Sonntag 3 Mai');
    expect(dayMonthYear(d), '3 Mai 2026');
    AppRegion.apply(lang: 'pt', country: 'PT');
    expect(dayMonth(d), '3 mai.');
    expect(dayMonthYear(d), '3 mai. 2026');
  });

  test('English outside the US keeps "Sep"; German weekdays keep the dot', () {
    final sep = DateTime(2026, 9, 13); // a Sunday
    for (final c in ['GB', 'AU', 'NL']) {
      AppRegion.apply(lang: 'en', country: c);
      expect(dayMonth(sep), '13 Sep', reason: c);
      expect(dayMonthYear(sep), '13 Sep 2026', reason: c);
      expect(weekdayDayMonth(sep), 'Sunday 13 Sep', reason: c);
      expect(monthShort(9), 'Sep', reason: c);
    }
    AppRegion.apply(lang: 'en', country: 'US');
    expect(dayMonth(sep), 'Sep 13');
    AppRegion.apply(lang: 'de', country: 'DE');
    expect(weekdayShort(sep), 'So.');
    AppRegion.apply(lang: 'nl', country: 'NL');
    expect(weekdayShort(sep), 'zo');
  });

  test('season label', () {
    expect(seasonLabel('2026-11-13', south: false), '2026');
    expect(seasonLabel('2026-11-13', south: true), '2026/27');
    expect(seasonLabel('2027-03-01', south: true), '2026/27');
  });
}
