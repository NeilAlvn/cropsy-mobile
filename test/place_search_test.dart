import 'package:cropsy/features/location/place_search.dart';
import 'package:flutter_test/flutter_test.dart';

const _body = '''
{"results":[
 {"name":"Austin","latitude":30.26715,"longitude":-97.74306,"country_code":"US","admin1":"Texas","country":"United States"},
 {"name":"London","latitude":51.50853,"longitude":-0.12574,"country_code":"GB","admin1":"England","country":"United Kingdom"},
 {"name":"Nowhere","latitude":1.0,"longitude":2.0}
]}
''';

void main() {
  test('parses name, region and country into a label', () {
    final hits = parsePlaces(_body);
    expect(hits.length, 2, reason: 'rows without a country are dropped');
    expect(hits.first.label, 'Austin, Texas, US');
    expect(hits.first.countryCode, 'US');
    expect(hits.first.lat, closeTo(30.27, 0.01));
    expect(hits[1].label, 'London, England, GB');
  });

  test('no results or bad json gives an empty list', () {
    expect(parsePlaces('{}'), isEmpty);
    expect(parsePlaces('oops'), isEmpty);
  });
}
