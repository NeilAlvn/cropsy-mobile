import 'package:cropsy/design/brutal.dart';
import 'package:cropsy/design/colors.dart';
import 'package:cropsy/design/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A pill with no colour of its own fills with the accent. This is a
/// regression test: when the colour tokens became getters for dark mode, the
/// default came off the constructor and every such button painted transparent,
/// white label on a white card.
void main() {
  testWidgets('a primary pill without a colour still has a fill', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PrimaryButton(label: 'Sync now', onPressed: () {}),
      ),
    ));

    final box = tester.widget<Container>(
      find.descendant(of: find.byType(PrimaryButton), matching: find.byType(Container)).first,
    );
    final fill = (box.decoration as BoxDecoration).color;
    expect(fill, isNotNull);
    expect(fill, AppColors.accent);
  });

  testWidgets('a disabled pill swaps tokens rather than fading', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PrimaryButton(label: 'Sync now', onPressed: null)),
    ));

    final box = tester.widget<Container>(
      find.descendant(of: find.byType(PrimaryButton), matching: find.byType(Container)).first,
    );
    expect((box.decoration as BoxDecoration).color, AppColors.tile);
  });

  /// Shape tokens have to answer a scheme change too. As `static final` fields
  /// they were computed once, so whichever scheme drew first kept its hairline
  /// and its drop shadow for the rest of the session.
  test('the shape tokens follow the scheme rather than the first read', () {
    addTearDown(() => AppColors.scheme.value = AppPalette.light);

    AppColors.scheme.value = AppPalette.light;
    final lightBorder = Neo.border.top.color;
    final lightShadow = Neo.float.single.color;

    AppColors.scheme.value = AppPalette.dark;
    expect(Neo.border.top.color, isNot(lightBorder));
    expect(Neo.float.single.color.a, greaterThan(lightShadow.a));
  });
}
