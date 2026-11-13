/// Town search anywhere in the world through the phone's own geocoder
/// (Apple / Google), so no server and no key. NL postcodes keep going
/// through `frostForPostcode` (PDOK, exact centroid).
library;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';

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

/// Null when the placemark has no name or country code (not a place to save).
@visibleForTesting
PlaceHit? placeHitFromPlacemark(Placemark p, double lat, double lon) {
  final name = [p.locality, p.name].firstWhere((s) => s != null && s.isNotEmpty, orElse: () => null);
  final cc = p.isoCountryCode;
  if (name == null || cc == null || cc.isEmpty) return null;
  return PlaceHit(
    name: name,
    label: [name, p.administrativeArea, cc.toUpperCase()].where((s) => s != null && s.isNotEmpty).join(', '),
    countryCode: cc.toUpperCase(),
    lat: lat,
    lon: lon,
  );
}

Future<List<PlaceHit>> _deviceGeocode(String q, String lang) async {
  final g = Geocoding(locale: Locale(lang));
  final hits = <PlaceHit>[];
  for (final l in (await g.locationFromAddress(q)).take(6)) {
    final marks = await g.placemarkFromCoordinates(l.latitude, l.longitude);
    final hit = marks.isEmpty ? null : placeHitFromPlacemark(marks.first, l.latitude, l.longitude);
    if (hit != null && !hits.any((h) => h.label == hit.label)) hits.add(hit);
  }
  return hits;
}

Future<List<PlaceHit>> searchPlaces(
  String query, {
  String lang = 'en',
  Future<List<PlaceHit>> Function(String q, String lang) geocode = _deviceGeocode,
}) async {
  final q = query.trim();
  if (q.length < 2) return const [];
  try {
    return await geocode(q, lang).timeout(const Duration(seconds: 15));
  } catch (_) {
    return const [];
  }
}
