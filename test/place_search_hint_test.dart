import 'package:cropsy/l10n/region.dart';
import 'package:cropsy/l10n/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppRegion.apply(lang: 'nl', country: 'NL'));

  test('NL/BE keep the postcode hint, byte for byte', () {
    for (final c in ['NL', 'BE', null]) {
      AppRegion.apply(lang: 'nl', country: c);
      expect(Str.placeSearchHint.pick('nl'), 'Plaats, regio of postcode');
      AppRegion.apply(lang: 'en', country: c);
      expect(Str.placeSearchHint.pick('en'), 'Town, region or postcode');
      expect(Str.placeSearchHint.pick('de'), 'Ort, Region oder Postleitzahl');
    }
  });

  test('US promises ZIP codes, everyone else only town or region', () {
    AppRegion.apply(lang: 'en', country: 'US');
    expect(Str.placeSearchHint.pick('en'), 'Town or ZIP code');
    AppRegion.apply(lang: 'en', country: 'GB');
    expect(Str.placeSearchHint.pick('en'), 'Town or region');
    AppRegion.apply(lang: 'de', country: 'DE');
    expect(Str.placeSearchHint.pick('de'), 'Ort oder Region');
    for (final c in ['GB', 'AU', 'DE']) {
      AppRegion.apply(lang: 'en', country: c);
      for (final l in ['en', 'nl', 'de', 'fr', 'sv', 'pt']) {
        expect(Str.placeSearchHint.pick(l).toLowerCase(), isNot(contains('postcode')));
      }
    }
  });
}
