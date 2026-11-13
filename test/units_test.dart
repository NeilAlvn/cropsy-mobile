import 'package:cropsy/l10n/region.dart';
import 'package:cropsy/l10n/units.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  tearDown(() => AppRegion.apply(lang: 'nl', country: 'NL'));

  test('US gets imperial', () {
    AppRegion.apply(lang: 'en', country: 'US');
    expect(tempC(20), '68°F');
    expect(tempBare(30), '86°');
    expect(rainMm(25.4), '1 in');
    expect(rainMm(3), '0.1 in');
    expect(lengthCm(30), '12 in');
    expect(depthMm(10), '0.4 in');
    expect(volumeL(10), '2.6 gal');
    expect(massKg(1), '2.2 lb');
    expect(areaM2(2), '22 sq ft');
    expect(distanceKm(1), '0.6 mi');
    expect([massUnit, volumeUnit], ['lb', 'gal']);
    expect(kgFromInput(2.20462), closeTo(1, 1e-6));
    expect(litresFromInput(1), closeTo(3.785, 1e-6));
    expect(inputFromKg(1), closeTo(2.20462, 1e-6));
  });

  test('US unit round trip and no -0', () {
    AppRegion.apply(lang: 'en', country: 'US');
    expect(inputFromLitres(litresFromInput(2)), closeTo(2, 1e-9));
    AppRegion.apply(lang: 'en', country: 'GB');
    expect(tempC(-0.2), '0°C');
  });

  test('UK and NL stay metric, NL with a decimal comma as today', () {
    AppRegion.apply(lang: 'en', country: 'GB');
    expect([tempC(20), rainMm(3), lengthCm(30), depthMm(10), volumeL(10), massKg(1.5), areaM2(2)],
        ['20°C', '3 mm', '30 cm', '10 mm', '10 L', '1.5 kg', '2 m²']);
    AppRegion.apply(lang: 'nl', country: 'NL');
    expect([tempC(20), rainMm(2.5), massKg(1.5)], ['20°C', '2,5 mm', '1,5 kg']);
    expect([massUnit, volumeUnit], ['kg', 'L']);
    expect(kgFromInput(1.5), 1.5);
  });

  test('temperature rounding, exact gates, spacing', () {
    AppRegion.apply(lang: 'en', country: 'GB');
    expect(tempC(20.5), '21°C');
    expect(tempC(-0.2), '0°C');
    AppRegion.apply(lang: 'nl', country: 'NL');
    expect(tempC(8.5, exact: true), '8,5°C');
    expect(tempC(8, exact: true, spaced: true), '8 °C');
    expect(tempBare(30), '30°');
    AppRegion.apply(lang: 'de', country: 'DE');
    expect(tempC(30), '30 °C');
    AppRegion.apply(lang: 'en', country: 'US');
    expect(tempC(8.5, exact: true), '47°F');
  });

  test('garden size buckets keep their stored m² values', () {
    AppRegion.apply(lang: 'en', country: 'US');
    expect(gardenSizeBuckets().map((b) => b.$2).toList(), [1, 4, 12, 30]);
    expect(gardenSizeBuckets().first.$1, '< 22 sq ft');
    AppRegion.apply(lang: 'nl', country: 'NL');
    expect(gardenSizeBuckets().map((b) => b.$1).toList(), ['< 2 m²', '2–5 m²', '5–20 m²', '> 20 m²']);
  });

  test('input units round-trip to metric', () {
    AppRegion.apply(lang: 'en', country: 'US');
    expect(massUnit, 'lb');
    expect(kgFromInput(2.20462), closeTo(1, 1e-9));
    expect(litresFromInput(2).round(), 8);
    AppRegion.apply(lang: 'nl', country: 'NL');
    expect(massUnit, 'kg');
    expect(litresFromInput(10).round(), 10);
  });

  test('imperial pot prefill is stable on an untouched save', () {
    AppRegion.apply(lang: 'en', country: 'US');
    expect(potInputText(10), '2.6');
    for (final l in [5, 10, 12, 20, 30, 50]) {
      expect(litresFromInput(double.parse(potInputText(l))).round(), l, reason: '$l L');
    }
  });

  test('fractional pot sizes are rounded, not truncated', () {
    AppRegion.apply(lang: 'nl', country: 'NL');
    expect([1.5, 7.5, 0.2].map(potInputText).toList(), ['2', '8', '0']);
    AppRegion.apply(lang: 'en', country: 'US');
    for (final l in [1.5, 7.5, 0.2]) {
      expect(litresFromInput(double.parse(potInputText(l))).round(), l.round(), reason: '$l L');
    }
  });
}
