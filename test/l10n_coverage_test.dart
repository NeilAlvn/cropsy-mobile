import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Which languages are shipped (every string must carry them). Grows per wave.
const shipped = ['nl', 'en', 'de'];

void main() {
  for (final file in ['lib/l10n/strings.dart', 'lib/l10n/mascot_lines.dart']) {
    test('$file carries every shipped language', () {
      final src = File(file).readAsStringSync();
      final blocks = RegExp(r'LocalizedText\((.*?)\);', dotAll: true).allMatches(src);
      expect(blocks, isNotEmpty);
      for (final b in blocks) {
        for (final lang in shipped) {
          expect(RegExp('\\b$lang:').hasMatch(b.group(1)!), isTrue,
              reason: 'missing $lang in: ${b.group(0)!.split('\n').first}');
        }
      }
    });
  }
}
