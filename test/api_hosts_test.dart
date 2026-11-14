import 'package:cropsy/config.dart';
import 'package:cropsy/features/garden/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final api = Uri.parse(apiBaseUrl);

  test('weather goes through the Cropsy backend, never Open-Meteo directly', () {
    final u = weatherUri(30.2672, -97.7431);
    expect(u.host, api.host);
    expect(u.path, '/api/weather');
    expect(u.queryParameters['latitude'], '30.27');
    expect(u.queryParameters['longitude'], '-97.74');
    expect(u.queryParameters['daily'], 'precipitation_sum,temperature_2m_min,temperature_2m_max,weathercode');
    expect(u.queryParameters.containsKey('apikey'), isFalse);
    expect(u.queryParameters.containsKey('past_days'), isFalse);
    expect(u.queryParameters['tz_offset'], DateTime.now().timeZoneOffset.inMinutes.toString());
  });

  test('weather query keeps the backend canonical key order (no 308)', () {
    expect(weatherUri(1, 2).query.split('&').map((p) => p.split('=').first).toList(),
        ['latitude', 'longitude', 'daily', 'forecast_days', 'timezone', 'tz_offset']);
  });
}
