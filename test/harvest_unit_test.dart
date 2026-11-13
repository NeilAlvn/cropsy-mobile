import 'package:cropsy/features/garden/plant_detail_screen.dart';
import 'package:cropsy/l10n/region.dart';
import 'package:cropsy/l10n/app_lang.dart';
import 'package:cropsy/l10n/strings.dart';
import 'package:cropsy/l10n/units.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppRegion.apply(lang: 'nl', country: 'NL'));

  testWidgets('Dutch user in the US: label says lb and the value converts', (tester) async {
    AppRegion.apply(lang: 'nl', country: 'US');
    (double, String)? result;
    await tester.pumpWidget(AppLangScope(
      notifier: AppLang('nl'),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () async => result = await showModalBottomSheet<(double, String)>(
                context: c,
                isScrollControlled: true,
                builder: (_) => const HarvestSheet(cropName: LocalizedText(nl: 'Sla', en: 'Lettuce')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('lb'), findsOneWidget);
    expect(find.text('kg'), findsNothing);
    await tester.tap(find.text('lb'));
    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text(Str.saveHarvest.pick('nl')));
    await tester.pumpAndSettle();
    expect(result!.$2, 'kg');
    expect(result!.$1, closeTo(0.907, 1e-9));
    expect(massKg(result!.$1), '2 lb');
  });
}
