// Changing the scheme has to keep the navigation stack.
//
// Colour tokens are static getters, so nothing is notified when the scheme
// flips; main.dart answers that by keying MaterialApp on the scheme, which
// rebuilds the tree. On its own that key also throws the navigator away, which
// is how changing the theme from a pushed screen used to dump you back on Home.
// The navigator's GlobalKey is what stops it: the element is re-parented into
// the new tree instead of being destroyed with the old one.
//
// This pins that. Whether a pushed page repaints is NOT asserted here: a route
// carries its page under the route's own GlobalKey, and reproducing that
// faithfully needs the real app, which cannot be pumped under `flutter test`
// (google_fonts fetches at runtime and hangs). That half is checked on device.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a scheme change keeps the pushed route', (tester) async {
    final scheme = ValueNotifier<Brightness>(Brightness.light);
    addTearDown(scheme.dispose);
    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ValueListenableBuilder<Brightness>(
        valueListenable: scheme,
        builder: (context, brightness, _) => MaterialApp(
          key: ValueKey(brightness),
          navigatorKey: navigator,
          theme: ThemeData(brightness: brightness),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(body: Text('pushed')),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('pushed'), findsOneWidget);

    scheme.value = Brightness.dark;
    await tester.pumpAndSettle();

    expect(find.text('pushed'), findsOneWidget,
        reason: 'the global key should carry the navigator into the new tree');

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget,
        reason: 'the route below it survived the rebuild too');
  });
}
