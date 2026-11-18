import 'dart:io';

import 'package:cropsy/db/database.dart';
import 'package:cropsy/features/onboarding/onboarding_screen.dart';
import 'package:cropsy/l10n/strings.dart';
import 'package:cropsy/timing/crop_snapshot.dart';
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

  test('the bar fills across the nine questions and no further', () {
    // The first question (location) is page 4; the last (crops) is page 12,
    // with the three statement cards on 9 to 11.
    expect(onboardingProgress(4), closeTo(1 / 9, 1e-9));
    expect(onboardingProgress(12), 1);
    // Hero, promises, hello, the loader, the payoff and the reminders ask sit
    // outside the range, which is why they pass no progress at all.
    expect(onboardingPageCount, 16);
  });

  group('the crops grid follows the answers', () {
    final crops = CropSnapshot.parse(File('assets/data/crops-snapshot.json').readAsStringSync()).crops;
    final bySlug = {for (final c in crops) c.slug: c};
    final grid = onboardingCropOptions;
    List<String> rank(Set<String> foods, [Set<String> interests = const {}]) =>
        rankCropOptions(grid, foods: foods, interests: interests, crop: (s) => bySlug[s]);

    test('every crop stays, only the order moves', () {
      expect(rank({'herbs'}, {'easy', 'fast'}).toSet(), grid.toSet());
      expect(rank({}), grid);
    });

    test('what you eat comes first, in grid order', () {
      final herbs = rank({'herbs'});
      expect(herbs.take(2), ['basil', 'coriander']);
      // Outside the match the grid's own order holds.
      expect(herbs.skip(2), grid.where((s) => !{'basil', 'coriander'}.contains(s)));
      expect(rank({'roots'}).take(2), ['carrot', 'beetroot']);
    });

    test('easy and fast reorder within the match', () {
      // Tomato (difficulty 2) drops behind courgette (1) for easy.
      expect(rank({'fruit'}, {'easy'}).take(4), ['courgette', 'tomato', 'chili', 'cucumber']);
      // Courgette 50 days, cucumber 55, tomato 60, chili 90.
      expect(rank({'fruit'}, {'fast'}).take(4), ['courgette', 'cucumber', 'tomato', 'chili']);
      // No data behind yield: it changes nothing.
      expect(rank({'vegetables'}, {'yield', 'cost'}), rank({'vegetables'}));
    });

    test('a crop the snapshot lacks sorts as a non-match', () {
      final r = rankCropOptions(['ghost', 'basil'], foods: {'herbs'}, interests: {'easy'}, crop: (s) => bySlug[s]);
      expect(r, ['basil', 'ghost']);
    });
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
