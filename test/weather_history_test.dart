import 'package:cropsy/features/garden/weather_service.dart';
import 'package:cropsy/features/location/place_search.dart';
import 'package:cropsy/timing/weather_adjust.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';

DayObservation obs(String d, num mm) => DayObservation(date: d, precipMm: mm, tempMinC: 5, tempMaxC: 15);

void main() {
  test('stored days come back as past days, a date seen twice is merged', () {
    final stored = mergeHistory(
      [obs('2026-11-10', 1), obs('2026-11-11', 2), obs('2026-11-12', 3)],
      [obs('2026-11-12', 4), obs('2026-11-13', 5), obs('2026-11-14', 9)],
      '2026-11-13',
    );
    expect(stored.map((o) => o.date), ['2026-11-10', '2026-11-11', '2026-11-12', '2026-11-13']);
    expect(stored[2].precipMm, 4); // max(3, 4)
    final days = withPastDays(stored, [obs('2026-11-13', 6), obs('2026-11-14', 9)], '2026-11-13');
    expect(days.map((o) => o.date), ['2026-11-10', '2026-11-11', '2026-11-12', '2026-11-13', '2026-11-14']);
    expect(days[3].precipMm, 6);
  });

  test('a later, emptier reading never erases earlier rain', () {
    final m = mergeHistory(
      [const DayObservation(date: '2026-11-13', precipMm: 14, tempMinC: 8, tempMaxC: 12, weatherCode: 63)],
      [const DayObservation(date: '2026-11-13', precipMm: 0, tempMinC: 6, tempMaxC: 10, weatherCode: 3)],
      '2026-11-13',
    );
    expect(m.single.precipMm, 14);
    expect(m.single.tempMinC, 6);
    expect(m.single.tempMaxC, 12);
    expect(m.single.weatherCode, 63);
  });

  test('history keeps at most 7 days before today', () {
    final old = [for (var d = 1; d <= 9; d++) obs('2026-11-0$d', 1)];
    expect(mergeHistory(old, [], '2026-11-10').first.date, '2026-11-03');
  });

  test('history location matches at 2 decimals, like weatherUri', () {
    expect(sameSpot({'lat': 52.3712, 'lon': 4.8991}, 52.3698, 4.9012), isTrue);
    expect(sameSpot({'lat': 52.37, 'lon': 4.90}, 52.38, 4.90), isFalse);
  });

  test('placemark maps to a PlaceHit', () {
    final h = placeHitFromPlacemark(
        const Placemark(locality: 'Austin', administrativeArea: 'Texas', isoCountryCode: 'us'), 30.27, -97.74)!;
    expect(h.label, 'Austin, Texas, US');
    expect(h.countryCode, 'US');
    expect(placeHitFromPlacemark(const Placemark(locality: 'X'), 1, 2), isNull);
  });

  test('searchPlaces uses the injected geocoder, min 2 chars, empty on error', () async {
    const hit = PlaceHit(name: 'A', label: 'A, NL', countryCode: 'NL', lat: 1, lon: 2);
    expect(await searchPlaces('Ams', geocode: (q, l) async => [hit]), [hit]);
    expect(await searchPlaces('A', geocode: (q, l) async => [hit]), isEmpty);
    expect(await searchPlaces('Ams', geocode: (q, l) async => throw Exception('x')), isEmpty);
  });
}
