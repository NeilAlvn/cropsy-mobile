import 'package:cropsy/l10n/strings.dart';
import 'package:cropsy/notifications/lifecycle.dart';
import 'package:cropsy/notifications/reminders.dart';
import 'package:cropsy/timing/replan.dart';
import 'package:cropsy/timing/types.dart';
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

  test('second chance lands two days after onboarding at 10:00', () {
    expect(Lifecycle.secondChanceTime(DateTime(2026, 11, 30, 23, 50)), DateTime(2026, 12, 2, 10));
  });

  test('second chance names the first step after it lands', () {
    PathNode node(String due) =>
        PathNode(id: due, kind: NodeKind.transplant, plannedDue: due, due: due);
    final tasks = [
      (plantId: 'a', cropSlug: 'basil', node: node('2026-11-20')),
      (plantId: 'b', cropSlug: 'tomato', node: node('2026-11-29')),
    ];
    final fire = DateTime(2026, 11, 20, 10);
    final s = Lifecycle.stepAfter(tasks, fire)!;
    expect((s.cropSlug, s.kind, s.days), ('tomato', NodeKind.transplant, 9));
    expect(Lifecycle.stepAfter(tasks.take(1).toList(), fire), isNull);
  });

  test('second chance body falls back to generic copy', () {
    final step = Str.secondChanceBody(const LocalizedText(nl: 'Tomaat uitplanten', en: 'Plant out tomato'), 9, trial: true);
    expect(step.pick('en'), 'Plant out tomato in 9 days. Start your free week to see every step of your season.');
    expect(step.pick('nl'), startsWith('Tomaat uitplanten over 9 dagen. '));
    expect(Str.secondChanceBody(null, 0, trial: false).pick('en'), 'Unlock the full season to see every step.');
  });

  test('app-open paywall: 2nd and 4th cold start, free, nothing else open', () {
    bool show(int n, {bool premium = false, bool onboarding = false, bool opened = false}) =>
        Lifecycle.appOpenPaywall(coldStart: n, premium: premium, onboarding: onboarding, paywallOpened: opened);
    expect([for (var n = 1; n <= 6; n++) show(n)], [false, true, false, true, false, false]);
    expect(show(2, premium: true), isFalse);
    expect(show(2, onboarding: true), isFalse);
    expect(show(4, opened: true), isFalse);
  });
}
