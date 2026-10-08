import 'package:cropsy/l10n/app_lang.dart';
import 'package:cropsy/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeLang maps device tags onto the six codes, English otherwise', () {
    expect(normalizeLang('de-AT'), 'de');
    expect(normalizeLang('pt_PT'), 'pt');
    expect(normalizeLang('SV'), 'sv');
    expect(normalizeLang('it'), 'en');
    expect(normalizeLang(null), 'en');
  });

  test('the picker list is the six languages, English first', () {
    expect(appLanguageCodes, ['en', 'nl', 'de', 'fr', 'sv', 'pt']);
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
    await tester.pumpWidget(app('nl'));
    expect(Str.tabGarden.of(ctx), 'Mijn tuin');
    await tester.pumpWidget(app('de')); // no German yet → English
    expect(Str.tabGarden.of(ctx), 'My garden');
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
}
