/// Town / postcode search anywhere in the world: Open-Meteo Geocoding (free,
/// no key; the device already calls Open-Meteo for the forecast). NL postcodes
/// keep going through `frostForPostcode` (PDOK, exact centroid).
library;

import 'dart:convert';
import 'dart:io';

class PlaceHit {
  const PlaceHit({required this.name, required this.label, required this.countryCode, required this.lat, required this.lon});
  final String name;

  /// "Austin, Texas, US": what the user sees and what we save as the place name.
  final String label;

  /// ISO 3166-1 alpha-2, upper case.
  final String countryCode;
  final double lat;
  final double lon;
}

List<PlaceHit> parsePlaces(String body) {
  try {
    final rows = (jsonDecode(body) as Map<String, dynamic>)['results'] as List? ?? const [];
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        if (r['country_code'] is String)
          PlaceHit(
            name: r['name'] as String,
            label: [r['name'], r['admin1'], r['country_code']].whereType<String>().join(', '),
            countryCode: (r['country_code'] as String).toUpperCase(),
            lat: (r['latitude'] as num).toDouble(),
            lon: (r['longitude'] as num).toDouble(),
          ),
    ];
  } catch (_) {
    return const [];
  }
}

Future<List<PlaceHit>> searchPlaces(String query, {String lang = 'en'}) async {
  final q = query.trim();
  if (q.length < 2) return const [];
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': q,
      'count': '6',
      'language': lang,
      'format': 'json',
    });
    final res = await (await client.getUrl(uri)).close();
    if (res.statusCode != 200) return const [];
    return parsePlaces(await res.transform(utf8.decoder).join());
  } catch (_) {
    return const [];
  } finally {
    client.close();
  }
}
