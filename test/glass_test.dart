import 'package:cropsy/design/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('glass blurs the backdrop, and goes solid under high contrast',
      (tester) async {
    Widget app({required bool highContrast}) => MediaQuery(
          data: MediaQueryData(highContrast: highContrast),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: GlassSurface(child: SizedBox(width: 64, height: 64)),
          ),
        );

    await tester.pumpWidget(app(highContrast: false));
    expect(find.byType(BackdropFilter), findsOneWidget);

    // Base 10: reduced transparency and increased contrast drop the blur.
    await tester.pumpWidget(app(highContrast: true));
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
