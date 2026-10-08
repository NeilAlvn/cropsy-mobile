import 'package:cropsy/l10n/app_lang.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeLang maps device tags onto shipped codes, English otherwise', () {
    expect(normalizeLang('de-AT'), 'de');
    expect(normalizeLang('NL'), 'nl');
    // Planned but not shipped: English until the wave lands.
    expect(normalizeLang('fr'), 'en');
    expect(normalizeLang('pt_PT'), 'en');
    expect(normalizeLang('it'), 'en');
    expect(normalizeLang(null), 'en');
  });

  test('the stored language keeps a planned code the app does not speak yet', () {
    expect(shippedLanguages, isNot(contains('fr')));
    expect(plannedLang('fr-FR'), 'fr');
    expect(normalizeLang('fr-FR'), 'en');
    expect(plannedLang('it'), 'en');
  });

  test('six languages planned, the picker offers only the shipped ones', () {
    expect(appLanguages.map((l) => l.$1), ['en', 'nl', 'de', 'fr', 'sv', 'pt']);
    expect(appLanguages.map((l) => l.$1), containsAll(shippedLanguages));
    expect(pickerLanguages.length, shippedLanguages.length);
    expect(pickerLanguages.first.$1, 'en');
    expect(languageName('sv'), 'Svenska');
    expect(languageName('xx'), 'English');
  });

  testWidgets('of(context) reads the scoped language with English fallback', (tester) async {
    late BuildContext ctx;
    Widget app(String code) => AppLangScope(
          notifier: AppLang(code),
          child: Builder(builder: (c) {
            ctx = c;
            return const SizedBox();
          }),
        );
    const t = LocalizedText(nl: 'Mijn tuin', en: 'My garden');
    await tester.pumpWidget(app('nl'));
    expect(t.of(ctx), 'Mijn tuin');
    await tester.pumpWidget(app('de')); // no German in this literal → English
    expect(t.of(ctx), 'My garden');
  });

  testWidgets('MaterialApp accepts every supported locale', (tester) async {
    for (final (code, _) in appLanguages) {
      await tester.pumpWidget(MaterialApp(
        locale: Locale(code),
        supportedLocales: [for (final (c, _) in appLanguages) Locale(c)],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const SizedBox(),
      ));
      expect(Localizations.localeOf(tester.element(find.byType(SizedBox))).languageCode, code);
    }
  });

  test('every picker entry is a code the app can speak', () {
    for (final (code, name) in pickerLanguages) {
      expect(normalizeLang(code), code);
      expect(name, isNotEmpty);
    }
  });
}
