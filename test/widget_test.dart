// Smoke test for the pre-UX shell: it boots to its Scaffold and shows the
// loading state before the async asset read resolves. The snapshot-parsing +
// engine path itself is proven in base_schedule_test / weather_adjust_test
// against the same JSON, so this only checks the app wires up and runs.

import 'package:cropsy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shell boots to its Scaffold', (tester) async {
    await tester.pumpWidget(const CropsyApp());

    // Boots into the harness Scaffold with its title bar.
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Cropsy — shell'), findsOneWidget);
    // First frame shows the loading spinner before the async asset load lands.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
