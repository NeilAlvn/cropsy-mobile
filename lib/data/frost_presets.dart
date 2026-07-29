/// Bundled frost presets for onboarding (F3) and the location picker. In the
/// real app the frost profile comes from `GET /api/frost?lat=&lon=` with a
/// bundled national default offline (API contract §3). For the prototype we skip
/// the network and map a place — picked from the list, typed in, or "detected"
/// from the device — onto a representative NL/BE frost profile.
library;

import 'dart:math';

import '../timing/types.dart';

class FrostRegion {
  const FrostRegion(
    this.name,
    this.profile, {
    required this.lat,
    required this.lon,
    this.cities = const [],
  });

  final String name;
  final FrostProfile profile;

  /// Representative coordinate — used to snap a detected/typed location onto the
  /// nearest region (the prototype's stand-in for the backend frost lookup).
  final double lat;
  final double lon;

  /// Searchable place names that belong to this region, so a user can type their
  /// own town (e.g. "Rotterdam", "Antwerp") instead of picking a broad region.
  final List<String> cities;

  /// True if [query] matches this region's name or one of its cities.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    return cities.any((c) => c.toLowerCase().contains(q));
  }
}

/// Coarse but plausible; enough to make the "why" in crop detail read true.
const frostRegions = <FrostRegion>[
  FrostRegion('Randstad (Amsterdam/Utrecht)',
      FrostProfile(lastFrost: '2026-04-15', firstFrost: '2026-11-01'),
      lat: 52.31, lon: 4.94,
      cities: ['Amsterdam', 'Utrecht', 'Amersfoort', 'Almere', 'Hilversum']),
  FrostRegion('Coastal (Den Haag/Rotterdam)',
      FrostProfile(lastFrost: '2026-04-08', firstFrost: '2026-11-12'),
      lat: 51.97, lon: 4.35,
      cities: ['Den Haag', 'The Hague', 'Rotterdam', 'Delft', 'Leiden', 'Haarlem']),
  FrostRegion('South (Maastricht/Limburg)',
      FrostProfile(lastFrost: '2026-04-20', firstFrost: '2026-10-28'),
      lat: 50.85, lon: 5.69,
      cities: ['Maastricht', 'Limburg', 'Eindhoven', 'Venlo', 'Heerlen', 'Roermond']),
  FrostRegion('North-east (Groningen/Twente)',
      FrostProfile(lastFrost: '2026-04-28', firstFrost: '2026-10-22'),
      lat: 53.22, lon: 6.57,
      cities: ['Groningen', 'Twente', 'Enschede', 'Assen', 'Zwolle', 'Leeuwarden']),
  FrostRegion('Belgium (Antwerp/Brussels)',
      FrostProfile(lastFrost: '2026-04-12', firstFrost: '2026-11-05'),
      lat: 51.05, lon: 4.40,
      cities: ['Antwerp', 'Antwerpen', 'Brussels', 'Brussel', 'Gent', 'Ghent', 'Leuven']),
];

final defaultRegion = frostRegions.first;

/// Prototype stand-in for the device's GPS fix. In production this comes from
/// the platform location service; here it's a fixed coordinate (central NL) so
/// "Use my current location" resolves deterministically in a demo.
const demoDeviceLat = 52.13;
const demoDeviceLon = 5.29;

/// Snap a coordinate onto the nearest preset region (equirectangular distance —
/// fine at these latitudes). The prototype's offline substitute for the frost
/// API's lat/lon lookup.
FrostRegion nearestRegion(double lat, double lon) {
  FrostRegion best = frostRegions.first;
  double bestD = double.infinity;
  for (final r in frostRegions) {
    final dLat = (r.lat - lat) * pi / 180;
    final dLon = (r.lon - lon) * pi / 180 * cos(lat * pi / 180);
    final d = dLat * dLat + dLon * dLon;
    if (d < bestD) {
      bestD = d;
      best = r;
    }
  }
  return best;
}
