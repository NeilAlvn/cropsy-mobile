import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every bundled crop has a photo', () {
    final snap = jsonDecode(File('assets/data/crops-snapshot.json').readAsStringSync()) as Map<String, dynamic>;
    final crops = (snap['crops'] as List).cast<Map<String, dynamic>>();
    final missing = [
      for (final c in crops)
        if (!File('assets/crops/${c['image'] ?? '${c['slug']}.jpg'}').existsSync()) c['slug'],
    ];
    expect(missing, isEmpty);
  });
}
