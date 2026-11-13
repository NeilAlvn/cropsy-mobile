/// Frost profile for a place: device GPS or an NL postcode → `GET /api/frost`
/// (API-CONTRACT §3). Offline or on failure the caller falls back to the
/// bundled presets, so the app is never without a schedule.
library;

import 'dart:convert';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../config.dart';
import '../../timing/types.dart';

class FrostLookup {
  const FrostLookup({required this.profile, required this.lat, required this.lon, required this.source, this.country});
  final FrostProfile profile;
  final double lat;
  final double lon;

  /// ISO-2 country of the GPS fix (device reverse geocoder); null if unknown.
  final String? country;

  /// Always `open-meteo` (anything else is rejected in `_get`) — shown in the "based on" row.
  final String source;
}

Future<FrostLookup?> _get(Map<String, String> query) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    const limit = Duration(seconds: 15);
    final req = await client.getUrl(Uri.parse('$apiBaseUrl/api/frost').replace(queryParameters: query));
    final res = await req.close().timeout(limit);
    if (res.statusCode != 200) return null;
    final j = jsonDecode(await res.transform(utf8.decoder).join().timeout(limit)) as Map<String, dynamic>;
    // An old backend answers with NL `fallback` dates or a hemisphere-less
    // profile; never save those.
    if (j['source'] != 'open-meteo' || j['hemisphere'] == null) return null;
    return FrostLookup(
      profile: FrostProfile.fromJson(j),
      lat: (j['lat'] as num).toDouble(),
      lon: (j['lon'] as num).toDouble(),
      source: j['source'] as String,
    );
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}

Future<FrostLookup?> frostForCoordinate(double lat, double lon) =>
    _get({'lat': lat.toStringAsFixed(2), 'lon': lon.toStringAsFixed(2)});

Future<FrostLookup?> frostForPostcode(String postcode) => _get({'postcode': postcode.trim()});

/// One GPS fix at low accuracy (frost cells are 0.1°; we never need more).
/// null when permission is denied or location is off.
Future<FrostLookup?> frostForDevice() async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
  );
  final hit = await frostForCoordinate(pos.latitude, pos.longitude);
  if (hit == null) return null;
  return FrostLookup(
    profile: hit.profile,
    lat: hit.lat,
    lon: hit.lon,
    source: hit.source,
    country: await _countryAt(pos.latitude, pos.longitude),
  );
}

/// The phone's own reverse geocoder (CLGeocoder / Android Geocoder). The
/// country decides units, presets and euro display, so it must come from where
/// the user is, not from the phone's region setting. null offline or on error.
Future<String?> _countryAt(double lat, double lon) async {
  try {
    final marks = await Geocoding().placemarkFromCoordinates(lat, lon).timeout(const Duration(seconds: 8));
    final code = marks.isEmpty ? null : marks.first.isoCountryCode;
    return (code == null || code.isEmpty) ? null : code.toUpperCase();
  } catch (_) {
    return null;
  }
}
