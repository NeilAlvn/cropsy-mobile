/// The user's place, as last chosen: name, frost profile, where the dates came
/// from, and the country. Stored in `app_meta` (local only) and restored on
/// every launch by `GardenRepository.create`.
library;

import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import '../../timing/types.dart';

class SavedLocation {
  const SavedLocation({
    required this.name,
    required this.profile,
    required this.source,
    this.country,
    this.lat,
    this.lon,
    this.postcode,
  });

  static const metaKey = 'location.v1';

  final String name;
  final FrostProfile profile;

  /// `open-meteo` | `preset`.
  final String source;

  /// ISO 3166-1 alpha-2, upper case. null = unknown (use the device region).
  final String? country;
  final double? lat;
  final double? lon;
  final String? postcode;

  String encode() => jsonEncode({
        'name': name,
        'profile': profile.toJson(),
        'source': source,
        'country': country,
        'lat': lat,
        'lon': lon,
        'postcode': postcode,
      });

  static SavedLocation? decode(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return SavedLocation(
        name: j['name'] as String,
        profile: FrostProfile.fromJson(j['profile'] as Map<String, dynamic>),
        source: j['source'] as String,
        country: j['country'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
        postcode: j['postcode'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// A looked-up place saved before the climate curve existed: fetch it once.
bool needsClimate(SavedLocation l) =>
    l.source == 'open-meteo' && l.profile.weeklyTmax == null && l.lat != null && l.lon != null;

/// The device's region setting (Settings → General → Language & Region).
String? deviceCountry() => PlatformDispatcher.instance.locale.countryCode?.toUpperCase();

/// The NL/BE presets, postcode lookup and Randstad shortcut only make sense
/// there. Unknown country keeps today's behaviour.
bool usesNlBePresets(String? country) => country == null || country == 'NL' || country == 'BE';
