import 'dart:io';

import 'package:cropsy/data/crop_content.dart';
import 'package:cropsy/timing/crop_snapshot.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final crops = CropSnapshot.parse(File('assets/data/crops-snapshot.json').readAsStringSync()).crops;
  Crop crop(String slug) => crops.firstWhere((c) => c.slug == slug);

  test('harvest counts from planting out, not from indoor sowing', () {
    // Courgette: sow indoors LF+0..3w, plant out LF+4..6w, harvest 50-70 days.
    const frost = FrostProfile(lastFrost: '2026-04-15', firstFrost: '2026-11-01');
    final spans = harvestSpans(crop('courgette'), frost);
    expect(spans, hasLength(1));
    // Plant out 13-27 May → harvest 2 Jul (13 May + 50) .. 5 Aug (27 May + 70).
    expect(spans.single.start, DateTime.utc(2026, 7, 2));
    expect(spans.single.end, DateTime.utc(2026, 8, 5));
    expect(firstHarvestDate(crop('courgette'), frost), '2026-07-02');
  });
}
