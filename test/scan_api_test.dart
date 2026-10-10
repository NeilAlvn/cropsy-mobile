import 'package:cropsy/scan/scan_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scan paths carry the reader language', () {
    expect(scanPath('/api/identify', 'de'), '/api/identify?lang=de');
    expect(scanPath('/api/diagnose', 'xx'), '/api/diagnose?lang=en');
  });

  test('the disclaimer follows the reader language, English otherwise', () {
    final body = <String, dynamic>{'disclaimer': {'en': 'Not advice', 'de': 'Keine Beratung'}};
    expect(disclaimerFor(body, 'de'), 'Keine Beratung');
    expect(disclaimerFor(body, 'nl'), 'Not advice');
    expect(disclaimerFor(const {}, 'de'), isNull);
  });
}
