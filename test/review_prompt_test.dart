import 'package:cropsy/features/garden/review_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final first = DateTime(2026, 6, 1);

  bool ask({int wins = 1, int days = 0, DateTime? lastAsk}) => ReviewPrompt.shouldAsk(
        now: first.add(Duration(days: days)),
        wins: wins,
        firstWin: first,
        lastAsk: lastAsk,
      );

  test('asks after the first win, the same day', () => expect(ask(), isTrue));

  test('waits for a win', () => expect(ask(wins: 0), isFalse));

  test('leaves 120 days between asks', () {
    final last = first.add(const Duration(days: 3));
    expect(ask(days: 122, lastAsk: last), isFalse);
    expect(ask(days: 123, lastAsk: last), isTrue);
  });

  test('a single step or a harvest each clear the bar', () {
    expect(ask(wins: ReviewPrompt.stepWin), isTrue);
    expect(ask(wins: ReviewPrompt.harvestWin), isTrue);
  });
}
