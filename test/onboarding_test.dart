import 'package:cropsy/db/database.dart';
import 'package:cropsy/features/onboarding/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the garden kind falls out of space and size alone', () {
    // An allotment is either called one, or a big back garden.
    expect(gardenKindFor(spaces: {'farm'}, sizeBucket: 0), GardenKind.allotment);
    expect(gardenKindFor(spaces: {'backyard'}, sizeBucket: 2), GardenKind.allotment);
    expect(gardenKindFor(spaces: {'backyard'}, sizeBucket: 1), GardenKind.garden);
    // A small "farm" is still an allotment: the || is not shadowed by the &&.
    expect(gardenKindFor(spaces: {'farm', 'balcony'}, sizeBucket: 0), GardenKind.allotment);
    // Everything else is containers.
    expect(gardenKindFor(spaces: {'balcony'}, sizeBucket: 3), GardenKind.balcony);
    expect(gardenKindFor(spaces: {'indoor'}, sizeBucket: 3), GardenKind.balcony);
    expect(gardenKindFor(spaces: {}, sizeBucket: 0), GardenKind.balcony);
  });

  test('the bar fills across the six questions and no further', () {
    // The first question is page 2; the last is page 7.
    expect(onboardingProgress(2), closeTo(1 / 6, 1e-9));
    expect(onboardingProgress(7), 1);
    // Hero, hello and the payoff sit outside the range, which is why they
    // pass no progress at all.
    expect(onboardingPageCount, 9);
  });
}
