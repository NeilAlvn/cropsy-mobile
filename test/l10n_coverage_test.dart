import 'dart:io';

import 'package:cropsy/l10n/app_lang.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every `nl:` in the l10n sources must be matched by one `<lang>:` per shipped
/// language. Counting named arguments in the code (string literals and
/// comments stripped) sees every shape a string can take: const fields,
/// switch-expression functions, list entries.
void main() {
  const files = {'lib/l10n/strings.dart': 400, 'lib/l10n/mascot_lines.dart': 25};

  for (final MapEntry(key: file, value: floor) in files.entries) {
    final src = File(file).readAsStringSync();
    final code = stripStringsAndComments(src);
    int count(String lang) => RegExp('\\b$lang:').allMatches(code).length;

    test('$file carries every shipped language', () {
      final nl = count('nl');
      expect(nl, greaterThan(floor), reason: 'too few strings found; is the stripper broken?');
      for (final lang in shippedLanguages) {
        expect(count(lang), nl, reason: '$lang: count differs from nl:');
      }
    });

    test('$file never reads a nullable side directly', () {
      // `${x.de}` renders "null" when the side is missing; `.pick('de')` is the rule.
      final bad = RegExp(r'\.(de|fr|sv|pt)\}|\.(de|fr|sv|pt)\b(?!\s*:)').allMatches(src);
      final lines = src.split('\n');
      String at(int offset) {
        final n = '\n'.allMatches(src.substring(0, offset)).length;
        return '${n + 1}: ${lines[n].trim()}';
      }

      expect([for (final m in bad) at(m.start)], isEmpty);
    });
  }

  test('the stripper drops literals, interpolations and comments', () {
    const src = r'''a(nl: 'x nl: ${b ? 'de:' : "fr:"} \' en:', de: "y") // sv: z
/* pt: */ c(en: 1)''';
    expect(stripStringsAndComments(src), 'a(nl: , de: ) \n c(en: 1)');
  });
}

/// Dart source with string literals (including nested `${...}` and `\'`
/// escapes) and comments removed. Good enough for the l10n files, which use no
/// raw or triple-quoted strings.
String stripStringsAndComments(String s) {
  final out = StringBuffer();
  _skipCode(s, 0, out);
  return out.toString();
}

int _skipString(String s, int i) {
  final q = s[i++];
  while (i < s.length && s[i] != q) {
    if (s[i] == r'\') {
      i += 2;
    } else if (s.startsWith(r'${', i)) {
      i = _skipCode(s, i + 2, null);
    } else {
      i++;
    }
  }
  return i + 1;
}

/// Code up to the matching `}` (or the end, when writing to [sink]).
int _skipCode(String s, int i, StringBuffer? sink) {
  var depth = 1;
  while (i < s.length) {
    final c = s[i];
    if (c == "'" || c == '"') {
      i = _skipString(s, i);
      continue;
    }
    if (s.startsWith('//', i)) {
      final end = s.indexOf('\n', i);
      i = end < 0 ? s.length : end;
      continue;
    }
    if (s.startsWith('/*', i)) {
      final end = s.indexOf('*/', i + 2);
      i = end < 0 ? s.length : end + 2;
      continue;
    }
    if (c == '{') depth++;
    if (c == '}' && --depth == 0 && sink == null) return i + 1;
    sink?.write(c);
    i++;
  }
  return i;
}
