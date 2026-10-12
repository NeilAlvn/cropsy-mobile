import 'package:cropsy/features/garden/gating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free gardens stop at three growing plants', () {
    expect(overPlantLimit(2, premium: false), isFalse);
    expect(overPlantLimit(3, premium: false), isTrue);
    expect(overPlantLimit(9, premium: true), isFalse);
  });

  test('home card rests seven days after it shows', () {
    expect(homeCardDue(null, '2026-10-12'), isTrue);
    expect(homeCardDue('2026-10-06', '2026-10-12'), isFalse);
    expect(homeCardDue('2026-10-05', '2026-10-12'), isTrue);
  });
}
