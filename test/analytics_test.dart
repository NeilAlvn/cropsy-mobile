/// The consent gate is the whole point of the analytics wrapper: if these pass,
/// an install that never says yes cannot start the SDK or send an event.
///
/// The yes path is deliberately not here — it calls into the native SDK, which
/// a unit test has no channel for. That path is covered by running the app.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:cropsy/analytics/analytics.dart';

void main() {
  test('no stored answer starts nothing', () async {
    await Analytics.init(null);
    expect(Analytics.live, isFalse);
  });

  test('a stored no starts nothing', () async {
    await Analytics.init('no');
    expect(Analytics.live, isFalse);
  });

  test('capture is a no-op while the gate is shut', () async {
    // Reaching the SDK here would throw: there is no platform channel.
    await Analytics.capture('plant_added', properties: {'crop': 'tomato'});
    expect(Analytics.live, isFalse);
  });

  test('turning consent off while nothing runs is harmless', () async {
    await Analytics.setConsent(false);
    expect(Analytics.live, isFalse);
  });
}
