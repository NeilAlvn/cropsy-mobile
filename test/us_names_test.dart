import 'dart:io';

import 'package:cropsy/l10n/region.dart';
import 'package:cropsy/timing/crop_snapshot.dart';
import 'package:cropsy/timing/us_crop_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppRegion.apply(lang: 'nl', country: 'NL'));
  final crops = CropSnapshot.parse(File('test/fixtures/crops-snapshot.json').readAsStringSync()).crops;

  test('every US name maps to a real crop', () {
    final slugs = crops.map((c) => c.slug).toSet();
    expect(usCropNames.keys.where((k) => !slugs.contains(k)), isEmpty);
  });

  test('US readers see US names, UK readers British', () {
    final courgette = crops.firstWhere((c) => c.slug == 'courgette');
    AppRegion.apply(lang: 'en', country: 'US');
    expect(courgette.names.pick('en'), 'Zucchini');
    AppRegion.apply(lang: 'en', country: 'GB');
    expect(courgette.names.pick('en'), 'Courgette');
  });
}
