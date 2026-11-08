import 'package:cropsy/features/garden/review_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final first = DateTime(2026, 6, 1);

  bool ask({int wins = 3, int days = 3, DateTime? lastAsk}) => ReviewPrompt.shouldAsk(
        now: first.add(Duration(days: days)),
        wins: wins,
        firstWin: first,
        lastAsk: lastAsk,
      );

  test('asks once there are enough wins and days', () => expect(ask(), isTrue));

  test('waits for enough wins', () => expect(ask(wins: 2), isFalse));

  test('never asks in the first days', () => expect(ask(wins: 9, days: 2), isFalse));

  test('leaves 120 days between asks', () {
    final last = first.add(const Duration(days: 3));
    expect(ask(days: 122, lastAsk: last), isFalse);
    expect(ask(days: 123, lastAsk: last), isTrue);
  });

  test('a harvest clears the win bar alone', () {
    expect(ask(wins: ReviewPrompt.harvestWin), isTrue);
    expect(ask(wins: ReviewPrompt.stepWin), isFalse);
  });
}
