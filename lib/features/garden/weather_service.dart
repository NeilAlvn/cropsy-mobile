/// Live daily weather for the overlay (API-CONTRACT §5): Open-Meteo, 7 days
/// back + 7 ahead, cached in AppMeta for six hours. Offline or on failure the
/// cache is used if present, else there is no overlay — the base schedule
/// stands and the app never invents a forecast.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../db/database.dart';
import '../../timing/weather_adjust.dart';

class WeatherService {
  WeatherService(this.db);
  final AppDatabase db;

  static const _key = 'weather_cache';
  static const _ttl = Duration(hours: 6);

  /// Observations for the location, or null when nothing is available.
  Future<List<DayObservation>?> observations(double lat, double lon) async {
    final cached = await _readCache(lat, lon);
    if (cached != null && cached.fresh) return cached.days;
    final fetched = await _fetch(lat, lon);
    if (fetched != null) {
      await _writeCache(lat, lon, fetched);
      return fetched;
    }
    return cached?.days; // stale beats nothing
  }

  Future<List<DayObservation>?> _fetch(double lat, double lon) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toStringAsFixed(2),
        'longitude': lon.toStringAsFixed(2),
        'daily': 'precipitation_sum,temperature_2m_min,temperature_2m_max,weathercode',
        'past_days': '7',
        'forecast_days': '7',
        'timezone': 'auto',
      });
      final res = await (await client.getUrl(uri)).close();
      if (res.statusCode != 200) return null;
      final j = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      final d = j['daily'] as Map<String, dynamic>;
      final time = (d['time'] as List).cast<String>();
      final rain = (d['precipitation_sum'] as List);
      final tmin = (d['temperature_2m_min'] as List);
      final tmax = (d['temperature_2m_max'] as List);
      // Open-Meteo answers `weathercode` under the name it was asked for, but
      // also serves the newer `weather_code` spelling; accept either, and a
      // response with neither simply has no condition to show.
      final code = (d['weathercode'] ?? d['weather_code']) as List?;
      return [
        for (var i = 0; i < time.length; i++)
          if (tmin[i] != null && tmax[i] != null)
            DayObservation(
              date: time[i],
              precipMm: (rain[i] as num?) ?? 0,
              tempMinC: tmin[i] as num,
              tempMaxC: tmax[i] as num,
              weatherCode: (code?[i] as num?)?.toInt(),
            ),
      ];
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<({List<DayObservation> days, bool fresh})?> _readCache(double lat, double lon) async {
    final row = await (db.select(db.appMeta)..where((t) => t.key.equals(_key))).getSingleOrNull();
    if (row == null) return null;
    final j = jsonDecode(row.value) as Map<String, dynamic>;
    if ((j['lat'] as num).toDouble() != lat || (j['lon'] as num).toDouble() != lon) return null;
    final at = DateTime.parse(j['at'] as String);
    // `weather_code` arrived after the first shipped cache, so it is read as
    // optional rather than behind a new key: a row written by the previous
    // build still parses, just without a condition, and the next refresh fills
    // it in. Bumping the key would have thrown away a usable offline forecast.
    final days = [
      for (final o in j['days'] as List) DayObservation.fromJson(o as Map<String, dynamic>),
    ];
    return (days: days, fresh: DateTime.now().difference(at) < _ttl);
  }

  Future<void> _writeCache(double lat, double lon, List<DayObservation> days) =>
      db.into(db.appMeta).insert(
            AppMetaCompanion.insert(
              key: _key,
              value: jsonEncode({
                'lat': lat,
                'lon': lon,
                'at': DateTime.now().toIso8601String(),
                'days': [
                  for (final o in days)
                    {
                      'date': o.date,
                      'precip_mm': o.precipMm,
                      'temp_min_c': o.tempMinC,
                      'temp_max_c': o.tempMaxC,
                      if (o.weatherCode != null) 'weather_code': o.weatherCode,
                    },
                ],
              }),
            ),
            mode: InsertMode.insertOrReplace,
          );
}
