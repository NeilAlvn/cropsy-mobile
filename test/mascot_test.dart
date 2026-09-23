import 'package:cropsy/design/mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required bool reduced, required Widget child}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

void main() {
  testWidgets('the mascot breathes at hero size and holds still inline', (tester) async {
    // A big mascot is the subject of the screen: it breathes, so its painted
    // box leaves the size it was given. `celebrating` is one image, so the
    // painted box is the whole character.
    await tester.pumpWidget(
      _app(reduced: false, child: const Mascot(MascotPose.celebrating, size: 96)),
    );
    await tester.pump(const Duration(milliseconds: 1300));
    expect(tester.getRect(find.byType(Image)).width, greaterThan(96));

    // A small one is a label next to a row: no ticker, no movement.
    await tester.pumpWidget(
      _app(reduced: false, child: const Mascot(MascotPose.celebrating, size: 40)),
    );
    await tester.pump(const Duration(milliseconds: 1300));
    expect(tester.getRect(find.byType(Image)).width, 40);
  });

  testWidgets('a layered pose splits into a swaying stem and a body, and only '
      'at hero size', (tester) async {
    await tester.pumpWidget(_app(reduced: false, child: const Mascot(MascotPose.idle, size: 96)));
    expect(find.byType(Image), findsNWidgets(2));
    // The stem leans; the body does not.
    await tester.pump(const Duration(milliseconds: 4100));
    final stem = tester.getRect(find.byType(Image).first);
    final body = tester.getRect(find.byType(Image).last);
    expect(stem.left, isNot(closeTo(body.left, 0.5)));

    // Inline, and under reduced motion, it is one flat image again.
    await tester.pumpWidget(_app(reduced: false, child: const Mascot(MascotPose.idle, size: 40)));
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpWidget(_app(reduced: true, child: const Mascot(MascotPose.idle, size: 96)));
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a pose change pops, and reduced motion swaps outright', (tester) async {
    await tester.pumpWidget(_app(reduced: false, child: const Mascot(MascotPose.idle, size: 40)));
    expect(tester.getRect(find.byType(Image)).width, 40);

    await tester.pumpWidget(
      _app(reduced: false, child: const Mascot(MascotPose.celebrating, size: 40)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      tester.getRect(find.byType(Image).first).width,
      lessThan(40),
      reason: 'the pop dips before it springs back',
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(_app(reduced: true, child: const Mascot(MascotPose.wave, size: 40)));
    await tester.pump();
    expect(find.byType(Image), findsOneWidget, reason: 'no cross-fade, so never two poses at once');
  });
}
