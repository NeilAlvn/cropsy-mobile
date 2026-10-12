import 'package:cropsy/notifications/lifecycle.dart';
import 'package:cropsy/notifications/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trial reminders land on day 3 and day 5 at 09:00', () {
    final t = Lifecycle.trialTimes(DateTime(2026, 10, 30, 22, 15));
    expect(t.nudge, DateTime(2026, 11, 2, 9));
    expect(t.ends, DateTime(2026, 11, 4, 9));
  });

  test('seasonal nudge aims at the next occurrence', () {
    expect(Lifecycle.nextYearly(DateTime(2026, 9, 1), 10, 1), DateTime(2026, 10, 1, 10));
    expect(Lifecycle.nextYearly(DateTime(2026, 10, 1, 9), 10, 1), DateTime(2026, 10, 1, 10));
    expect(Lifecycle.nextYearly(DateTime(2026, 10, 1, 10), 10, 1), DateTime(2027, 10, 1, 10));
    expect(Lifecycle.nextYearly(DateTime(2026, 10, 12), 2, 15), DateTime(2027, 2, 15, 10));
  });

  test('care reminders stay below the lifecycle range', () {
    expect(Reminders.isCareId(0), isTrue);
    expect(Reminders.isCareId(99), isTrue);
    expect(Reminders.isCareId(100), isFalse);
    expect(Reminders.isCareId(1000), isFalse);
  });
}
