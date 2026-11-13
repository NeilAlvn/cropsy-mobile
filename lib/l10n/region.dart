/// The user's region, as far as units, dates and copy care. Global like
/// `Intl.defaultLocale`: set at startup and whenever the place or the
/// language changes (`AppRegion.apply` / `setCountry`).
library;

import 'package:intl/intl.dart';

import '../features/location/saved_location.dart' show usesNlBePresets;
import '../timing/types.dart';

const _eurozone = {
  'AT', 'BE', 'HR', 'CY', 'EE', 'FI', 'FR', 'DE', 'GR', 'IE',
  'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PT', 'SK', 'SI', 'ES',
};

class AppRegion {
  static String? _country;

  /// ISO 3166-1 alpha-2, upper case; null = unknown.
  static String? get country => _country;
  static bool get isUS => _country == 'US';

  /// Imperial units: the US only.
  static bool get imperial => isUS;

  /// Euro amounts (harvest value, fallback prices) make sense here.
  /// Unknown country keeps today's behaviour.
  static bool get euro => _country == null || _eurozone.contains(_country);

  /// Dutch/Belgian copy, presets, postcode lookup.
  static bool get nlBe => usesNlBePresets(_country);

  /// `Intl.defaultLocale` for [lang] in [country]. English follows the
  /// country (US month-first, everything else day-first); other languages
  /// keep their bare code, exactly as before.
  static String intlLocale(String lang, String? country) {
    if (lang != 'en') return lang;
    return switch (country) { 'US' => 'en_US', 'AU' => 'en_AU', _ => 'en_GB' };
  }

  static void apply({required String lang, String? country}) {
    _country = country;
    Intl.defaultLocale = intlLocale(lang, country);
    LocalizedText.usEnglish = isUS;
    LocalizedText.dutchAlias = nlBe;
  }

  /// A new place: same language, new country.
  static void setCountry(String? country) =>
      apply(lang: (Intl.defaultLocale ?? 'en').substring(0, 2), country: country);
}
