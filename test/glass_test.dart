import 'package:cropsy/design/colors.dart';
import 'package:cropsy/design/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({bool highContrast = false}) => MediaQuery(
      data: MediaQueryData(highContrast: highContrast),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GlassSurface(child: const SizedBox(width: 64, height: 64)),
      ),
    );

/// The pane is the inner [DecoratedBox] — the one carrying the specular edge;
/// the outer one carries only the shadow.
double _specularAlpha(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((d) => d.decoration as BoxDecoration)
    .firstWhere((d) => d.border != null)
    .border!
    .top
    .color
    .a;

void main() {
  testWidgets('glass blurs the backdrop, and goes solid under high contrast',
      (tester) async {
    await tester.pumpWidget(_app());
    expect(find.byType(BackdropFilter), findsOneWidget);

    // Base 10: reduced transparency and increased contrast drop the blur.
    await tester.pumpWidget(_app(highContrast: true));
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('the specular edge is scaled by the scheme', (tester) async {
    addTearDown(() => AppColors.scheme.value = AppPalette.light);

    AppColors.scheme.value = AppPalette.light;
    await tester.pumpWidget(_app());
    final light = _specularAlpha(tester);

    AppColors.scheme.value = AppPalette.dark;
    await tester.pumpWidget(_app());
    final dark = _specularAlpha(tester);

    // A bright white ring on the dark canvas is the bug: dark has to catch
    // far less light than light does.
    expect(dark, lessThan(light / 2));
  });
}
