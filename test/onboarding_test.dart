import 'package:cropsy/db/database.dart';
import 'package:cropsy/features/onboarding/onboarding_screen.dart';
import 'package:cropsy/l10n/strings.dart';
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

  test('the bar fills across the seven questions and no further', () {
    // The first question is page 2; the last (crops) is page 8.
    expect(onboardingProgress(2), closeTo(1 / 7, 1e-9));
    expect(onboardingProgress(8), 1);
    // Hero, hello, the payoff and the reminders ask sit outside the range,
    // which is why they pass no progress at all.
    expect(onboardingPageCount, 11);
  });

  test('picks over the free limit wait in planning, in grid order', () {
    final grid = onboardingCropOptions;
    final picks = grid.take(5);
    final free = splitPicks(picks, 3);
    expect(free.growing, grid.take(3).toList());
    expect(free.planning, grid.skip(3).take(2).toList());
    // At or under the limit, and for premium's unreachable one, all grow.
    expect(splitPicks(picks, 5).planning, isEmpty);
    expect(splitPicks(picks, 1 << 30).growing, picks.toList());
  });

  test('every yes gets its answer back, in the order asked', () {
    expect(painEchoes({}), isEmpty);
    expect(painEchoes({'overload', 'timing'}), [Str.echoTiming, Str.echoOverload]);
    expect(painEchoes({'timing', 'midsummer', 'overload', 'unknown'}).length, 3);
  });
}
