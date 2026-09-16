import 'package:cropsy/l10n/app_lang.dart';
import 'package:cropsy/l10n/mascot_lines.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a line speaks the language the app is set to', (tester) async {
    late BuildContext ctx;
    Widget app(String code) => AppLangScope(
          notifier: AppLang(code),
          child: Builder(builder: (context) {
            ctx = context;
            return const SizedBox();
          }),
        );

    await tester.pumpWidget(app('nl'));
    expect(MascotLines.seasonEmpty.of(ctx), startsWith('Zet een plant'));

    await tester.pumpWidget(app('en'));
    expect(MascotLines.seasonEmpty.of(ctx), startsWith('Add a plant'));
  });

  test('the not-behind line counts in both languages, and never says overdue', () {
    final one = MascotLines.notBehind(
      step: const LocalizedText(nl: 'Uitplanten', en: 'Plant out'),
      days: 14,
      later: true,
      moved: 1,
    );
    expect(one.nl, contains('14 dagen later'));
    expect(one.nl, contains('1 volgende stap schuift'));
    expect(one.en, contains('1 upcoming step moves'));

    final many = MascotLines.notBehind(
      step: const LocalizedText(nl: 'Zaaien', en: 'Sow'),
      days: 3,
      later: false,
      moved: 4,
    );
    expect(many.nl, contains('4 volgende stappen schuiven'));
    expect(many.en, contains('4 upcoming steps move'));

    // PRD §7.2: the plan moves, the gardener is never behind.
    for (final line in [one, many, MascotLines.notBehindNothingMoved]) {
      expect(line.nl.toLowerCase(), isNot(contains('te laat')));
      expect(line.en.toLowerCase(), isNot(contains('overdue')));
    }
  });
}
