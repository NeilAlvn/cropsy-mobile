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
}
