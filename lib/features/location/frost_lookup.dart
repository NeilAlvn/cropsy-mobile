/// Frost profile for a place: device GPS or an NL postcode → `GET /api/frost`
/// (API-CONTRACT §3). Offline or on failure the caller falls back to the
/// bundled presets, so the app is never without a schedule.
library;

import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../../config.dart';
import '../../timing/types.dart';

class FrostLookup {
  const FrostLookup({required this.profile, required this.lat, required this.lon, required this.source});
  final FrostProfile profile;
  final double lat;
  final double lon;

  /// `open-meteo` | `fallback` (server default) — shown in the "based on" row.
  final String source;
}

Future<FrostLookup?> _get(Map<String, String> query) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final req = await client.getUrl(Uri.parse('$apiBaseUrl/api/frost').replace(queryParameters: query));
    final res = await req.close();
    if (res.statusCode != 200) return null;
    final j = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
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
  return frostForCoordinate(pos.latitude, pos.longitude);
}
