// nextStart: how a crop picked in onboarding gets started from a given day.
import 'dart:io';

import 'package:cropsy/timing/crop_snapshot.dart';
import 'package:cropsy/timing/engine.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final crops = CropSnapshot.parse(File('assets/data/crops-snapshot.json').readAsStringSync()).crops;
  Crop crop(String slug) => crops.firstWhere((c) => c.slug == slug);
  const frost = FrostProfile(lastFrost: '2026-04-15', firstFrost: '2026-11-01');

  test('in November a tomato waits for next spring and is sown, not planted out', () {
    final s = nextStart(crop('tomato'), frost, '2026-11-18')!;
    expect(s.open, isFalse);
    expect(s.method, isNot(MethodType.transplant));
    expect(s.start.startsWith('2027-'), isTrue);
  });

  test('inside a window the crop is open today', () {
    final first = nextStart(crop('tomato'), frost, '2026-01-01')!;
    final inside = nextStart(crop('tomato'), frost, first.start)!;
    expect(inside.open, isTrue);
    expect(inside.start, first.start);
  });

  test('every onboarding crop has a start in the next year', () {
    for (final slug in ['tomato', 'lettuce', 'courgette', 'basil', 'carrot', 'chili', 'cucumber', 'chives', 'coriander', 'beetroot']) {
      final s = nextStart(crop(slug), frost, '2026-11-18');
      expect(s, isNotNull, reason: slug);
      expect(s!.end.compareTo('2026-11-18') >= 0, isTrue, reason: slug);
      expect(s.start.compareTo('2027-11-18') <= 0, isTrue, reason: slug);
    }
  });
}
