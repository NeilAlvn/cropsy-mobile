import 'package:cropsy/l10n/region.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  tearDown(() => AppRegion.apply(lang: 'nl', country: 'NL'));

  test('intl locale per language and country', () {
    expect(AppRegion.intlLocale('en', 'US'), 'en_US');
    expect(AppRegion.intlLocale('en', 'GB'), 'en_GB');
    expect(AppRegion.intlLocale('en', 'AU'), 'en_AU');
    expect(AppRegion.intlLocale('en', 'NZ'), 'en_GB');
    expect(AppRegion.intlLocale('en', 'NL'), 'en_GB');
    expect(AppRegion.intlLocale('en', null), 'en_GB');
    expect(AppRegion.intlLocale('nl', 'US'), 'nl');
    expect(AppRegion.intlLocale('de', 'DE'), 'de');
  });

  test('flags follow the country', () {
    AppRegion.apply(lang: 'en', country: 'US');
    expect(Intl.defaultLocale, 'en_US');
    expect([AppRegion.isUS, AppRegion.imperial, AppRegion.euro, AppRegion.nlBe], [true, true, false, false]);
    AppRegion.apply(lang: 'en', country: 'GB');
    expect([AppRegion.imperial, AppRegion.euro, AppRegion.nlBe], [false, false, false]);
    AppRegion.apply(lang: 'nl', country: 'NL');
    expect(Intl.defaultLocale, 'nl');
    expect([AppRegion.imperial, AppRegion.euro, AppRegion.nlBe], [false, true, true]);
    AppRegion.apply(lang: 'de', country: 'DE');
    expect([AppRegion.euro, AppRegion.nlBe], [true, false]);
  });

  test('setCountry keeps the language', () {
    AppRegion.apply(lang: 'en', country: 'GB');
    AppRegion.setCountry('US');
    expect(Intl.defaultLocale, 'en_US');
  });

  test('US English names and the Dutch alias', () {
    const t = LocalizedText(nl: 'Courgette', en: 'Courgette', enUs: 'Zucchini');
    AppRegion.apply(lang: 'en', country: 'US');
    expect(t.pick('en'), 'Zucchini');
    expect(t.pick('nl'), 'Courgette');
    AppRegion.apply(lang: 'en', country: 'GB');
    expect(t.pick('en'), 'Courgette');
    const a = LocalizedText(nl: 'Sla', en: 'Lettuce');
    expect(a.other('en'), '', reason: 'no Dutch name under English titles outside NL/BE');
    AppRegion.apply(lang: 'en', country: 'NL');
    expect(a.other('en'), 'Sla', reason: 'unchanged for NL');
    expect(const LocalizedText(nl: 'a', en: 'b').withEnUs('c').enUs, 'c');
    expect(const LocalizedText(nl: 'a', en: 'b').withEnUs(null).enUs, isNull);
  });
}
