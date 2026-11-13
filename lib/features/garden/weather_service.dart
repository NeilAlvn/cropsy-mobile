/// Live daily weather for the overlay (API-CONTRACT §5): Open-Meteo through
/// the Cropsy backend (/api/weather), today + 6 ahead, cached in AppMeta for
/// six hours. The backend has no past days, so the app keeps its own record of
/// each day it has seen (`weather_history`) and serves the last 7 as past days. Offline or on failure the
/// cache is used if present, else there is no overlay — the base schedule
/// stands and the app never invents a forecast.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../config.dart';
import '../../db/database.dart';
import '../../timing/weather_adjust.dart';

@visibleForTesting
Uri weatherUri(double lat, double lon) => Uri.parse('$apiBaseUrl/api/weather').replace(queryParameters: {
      'latitude': lat.toStringAsFixed(2),
      'longitude': lon.toStringAsFixed(2),
      'daily': 'precipitation_sum,temperature_2m_min,temperature_2m_max,weathercode',
      'forecast_days': '7',
      'timezone': 'auto',
      'tz_offset': DateTime.now().timeZoneOffset.inMinutes.toString(),
    });

String _todayIso() => DateTime.now().toIso8601String().substring(0, 10);

String _isoMinus(String today, int days) =>
    DateTime.parse(today).subtract(Duration(days: days)).toIso8601String().substring(0, 10);

/// The stored record after a fetch: days up to [today] (and at most 7 days
/// back), one per date. A date seen before is merged, never replaced: MET's
/// "today" covers only the hours still to come, so a later fetch must not erase
/// earlier rain (precip/tmax/weathercode take the max, tmin the min).
@visibleForTesting
List<DayObservation> mergeHistory(List<DayObservation> stored, List<DayObservation> fetched, String today) {
  final from = _isoMinus(today, 7);
  final byDate = <String, DayObservation>{};
  for (final o in [...stored, ...fetched]) {
    final p = byDate[o.date];
    byDate[o.date] = p == null
        ? o
        : DayObservation(
            date: o.date,
            precipMm: max(p.precipMm, o.precipMm),
            tempMinC: min(p.tempMinC, o.tempMinC),
            tempMaxC: max(p.tempMaxC, o.tempMaxC),
            weatherCode: p.weatherCode == null || o.weatherCode == null
                ? p.weatherCode ?? o.weatherCode
                : max(p.weatherCode!, o.weatherCode!),
          );
  }
  return [
    for (final o in byDate.values)
      if (o.date.compareTo(from) >= 0 && o.date.compareTo(today) <= 0) o,
  ]..sort((a, b) => a.date.compareTo(b.date));
}

/// Stored days before [today] as past days, then the fetched series from today on.
@visibleForTesting
List<DayObservation> withPastDays(List<DayObservation> stored, List<DayObservation> fetched, String today) => [
      ...mergeHistory(stored, const [], today).where((o) => o.date.compareTo(today) < 0),
      ...fetched.where((o) => o.date.compareTo(today) >= 0),
    ];

/// Same place at the 2 decimals weatherUri sends.
@visibleForTesting
bool sameSpot(Map<String, dynamic> j, double lat, double lon) =>
    (j['lat'] as num).toStringAsFixed(2) == lat.toStringAsFixed(2) &&
    (j['lon'] as num).toStringAsFixed(2) == lon.toStringAsFixed(2);

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
    final today = _todayIso();
    if (fetched != null) {
      final history = mergeHistory(await _readHistory(lat, lon), fetched, today);
      await _writeHistory(lat, lon, history);
      final days = withPastDays(history, fetched, today);
      await _writeCache(lat, lon, days);
      return days;
    }
    return cached?.days; // stale beats nothing
  }

  static const _historyKey = 'weather_history';

  Future<List<DayObservation>> _readHistory(double lat, double lon) async {
    try {
      final row = await (db.select(db.appMeta)..where((t) => t.key.equals(_historyKey))).getSingleOrNull();
      if (row == null) return const [];
      final j = jsonDecode(row.value) as Map<String, dynamic>;
      if (!sameSpot(j, lat, lon)) return const [];
      return [for (final o in j['days'] as List) DayObservation.fromJson(o as Map<String, dynamic>)];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeHistory(double lat, double lon, List<DayObservation> days) => db.into(db.appMeta).insert(
        AppMetaCompanion.insert(
          key: _historyKey,
          value: jsonEncode({'lat': lat, 'lon': lon, 'days': [for (final o in days) _toJson(o)]}),
        ),
        mode: InsertMode.insertOrReplace,
      );

  static Map<String, dynamic> _toJson(DayObservation o) => {
        'date': o.date,
        'precip_mm': o.precipMm,
        'temp_min_c': o.tempMinC,
        'temp_max_c': o.tempMaxC,
        if (o.weatherCode != null) 'weather_code': o.weatherCode,
      };

  Future<List<DayObservation>?> _fetch(double lat, double lon) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = weatherUri(lat, lon);
      final res = await (await client.getUrl(uri)).close();
      if (res.statusCode != 200) return null;
      final j = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      final d = j['daily'] as Map<String, dynamic>;
      final time = (d['time'] as List).cast<String>();
      final rain = (d['precipitation_sum'] as List);
      final tmin = (d['temperature_2m_min'] as List);
      final tmax = (d['temperature_2m_max'] as List);
      // The backend answers `weathercode`, but the newer `weather_code`
      // spelling is accepted too, and a
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
                'days': [for (final o in days) _toJson(o)],
              }),
            ),
            mode: InsertMode.insertOrReplace,
          );
}
