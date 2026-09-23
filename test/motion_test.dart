import 'package:cropsy/design/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required bool reduced, required Widget child}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    );

/// The painted width of the pressable's child. `Transform.scale` keeps its
/// matrix in the render object, not on the widget, so the paint rect is what
/// tells us whether the press is showing.
double _paintedWidth(WidgetTester tester) =>
    tester.getRect(find.byType(SizedBox)).width;

void main() {
  const target = SizedBox(width: 80, height: 40);

  testWidgets('a press scales down and springs back', (tester) async {
    await tester.pumpWidget(
      _app(reduced: false, child: Pressable(onTap: () {}, child: target)),
    );
    expect(_paintedWidth(tester), 80);

    final gesture = await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    // The recognizer reports the press past its own deadline and the spring
    // ticks on the frames after that, so watch a handful of them.
    var narrowest = 80.0;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      narrowest = narrowest < _paintedWidth(tester) ? narrowest : _paintedWidth(tester);
    }
    expect(narrowest, lessThan(80));
    // The spring is underdamped, so it dips a little past 0.97 before settling.
    expect(narrowest, greaterThan(80 * 0.94));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_paintedWidth(tester), closeTo(80, 0.1));
  });

  testWidgets('reduced motion holds the press at its end state', (tester) async {
    await tester.pumpWidget(
      _app(reduced: true, child: Pressable(onTap: () {}, child: target)),
    );
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // No spring runs: the scale is simply there, at its end value.
    expect(_paintedWidth(tester), closeTo(80 * 0.97, 0.05));

    await gesture.up();
    await tester.pump();
    expect(_paintedWidth(tester), 80);
  });

  testWidgets('reduced motion drops the arrival animation entirely', (tester) async {
    await tester.pumpWidget(_app(reduced: true, child: const ArriveIn(index: 3, child: target)));
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);

    await tester.pumpWidget(_app(reduced: false, child: const ArriveIn(index: 3, child: target)));
    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    await tester.pumpAndSettle();
  });

  test('exits run shorter than enters', () {
    expect(Motion.exit.inMilliseconds, lessThan(Motion.standard.inMilliseconds));
  });

  testWidgets('the app preference only ever adds to the phone setting',
      (tester) async {
    addTearDown(() => AccessPrefs.reduceMotion.value = false);
    late BuildContext captured;

    Future<bool> reducedWith({required bool app, required bool platform}) async {
      AccessPrefs.reduceMotion.value = app;
      await tester.pumpWidget(_app(
        reduced: platform,
        child: Builder(builder: (context) {
          captured = context;
          return target;
        }),
      ));
      return Motion.of(captured).reduced;
    }

    expect(await reducedWith(app: false, platform: false), isFalse);
    // Either side asking for less motion is enough, and the phone's answer
    // cannot be overridden by the app's.
    expect(await reducedWith(app: true, platform: false), isTrue);
    expect(await reducedWith(app: false, platform: true), isTrue);
    expect(await reducedWith(app: true, platform: true), isTrue);
  });

  testWidgets('haptics go quiet when the preference is off', (tester) async {
    final buzzes = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') buzzes.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      AccessPrefs.haptics.value = true;
    });

    void fireAll() {
      Haptics.selection();
      Haptics.press();
      Haptics.complete();
    }

    AccessPrefs.haptics.value = true;
    fireAll();
    await tester.pump();
    expect(buzzes, hasLength(3));

    buzzes.clear();
    AccessPrefs.haptics.value = false;
    fireAll();
    await tester.pump();
    expect(buzzes, isEmpty);
  });
}
