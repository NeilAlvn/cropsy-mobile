import 'package:cropsy/l10n/mascot_lines.dart';
import 'package:cropsy/l10n/region.dart';
import 'package:cropsy/l10n/strings.dart';
import 'package:cropsy/l10n/units.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  tearDown(() => AppRegion.apply(lang: 'nl', country: 'NL'));

  test('NL text is exactly as before (decimal comma aside)', () {
    AppRegion.apply(lang: 'nl', country: 'NL');
    expect(Str.weatherRain(rainMm(2.5)).pick('nl'), '2,5 mm regen');
    expect(Str.adjustHeat(tempC(31)).pick('nl'), 'Hitte verwacht (31°C). Eerder water geven.');
    expect(Str.adjustHeat(tempC(31)).pick('en'), 'Heat expected (31°C). Water earlier.');
    expect(Str.adjustSoilCold(tempC(8)).pick('nl'), 'Bodem nog te koud (< 8°C). Uitgesteld tot het warmer is.');
    expect(Str.heatAhead(tempC(30)).pick('nl'),
        'Hitte op komst (30°C+). Potten drogen in een dag uit, dus water geven schuift naar voren.');
    expect(Str.adjustSoilCold(tempC(8.5, exact: true)).pick('nl'), 'Bodem nog te koud (< 8,5°C). Uitgesteld tot het warmer is.');
    expect(Str.faqDatesA(distanceKm(1)).pick('nl'), contains('afgerond op ~1 km'));
    expect(Str.potLitres(volumeL(10)).pick('en'), '10 L pot');
    expect(Str.potLitres(volumeL(10)).pick('nl'), '10 L pot');
    expect(Str.weatherRange(tempBare(21.4), tempBare(9.6)).pick('nl'), '21° / 10°');
    expect(Str.perSquare(lengthCm(30)).pick('nl'), 'Per vak van 30 cm');
    expect(Str.plannerBlurb(lengthCm(30)).pick('nl'), 'Leg je bed uit in vakjes van 30 cm.');
    expect(Str.frostBackbone(distanceKm(1)).pick('nl'),
        'Bepaalt je vorstdatums, de basis onder elke plantdatum. Afgerond op ~1 km, nooit gevolgd.');
    expect(Str.gardenSizeM2(areaM2(12)).pick('nl'), '12 m²');
    expect(Str.atLeastPot(volumeL(5)).pick('nl'), 'Minstens 5 L voor dit gewas');
    expect(MascotLines.insightRain(rainMm(12)).pick('en'),
        '12 mm of rain in the next three days. Skip watering and check the drainage holes.');
    expect(MascotLines.insightColdNight(tempC(-1), '12-03').pick('nl'),
        'Koude nacht op komst: -1°C op 12-03. Dek af of zet de potten binnen.');
  });

  test('US text uses imperial', () {
    AppRegion.apply(lang: 'en', country: 'US');
    expect(Str.adjustHeat(tempC(31)).pick('en'), 'Heat expected (88°F). Water earlier.');
    expect(Str.potLitres(volumeL(10)).pick('en'), '2.6 gal pot');
    expect(Str.heatAhead(tempC(30)).pick('en'), contains('86°F+'));
    expect(Str.perSquare(lengthCm(30)).pick('en'), 'Per 12 in square');
  });
}
