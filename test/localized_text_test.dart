import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const full = LocalizedText(
    nl: 'Zaaien', en: 'Sow', de: 'Säen', fr: 'Semer', sv: 'Så', pt: 'Semear',
  );
  const two = LocalizedText(nl: 'Oogst', en: 'Harvest');

  test('pick returns the asked language when present', () {
    expect(full.pick('de'), 'Säen');
    expect(full.pick('sv'), 'Så');
    expect(full.pick('nl'), 'Zaaien');
  });

  test('pick falls back to English for a missing language, never Dutch', () {
    expect(two.pick('de'), 'Harvest');
    expect(two.pick('pt'), 'Harvest');
    expect(two.pick('xx'), 'Harvest');
  });

  test('has reports which sides exist', () {
    expect(two.has('en'), isTrue);
    expect(two.has('nl'), isTrue);
    expect(two.has('fr'), isFalse);
    expect(full.has('fr'), isTrue);
  });

  test('other gives the subtitle language and is empty when identical', () {
    expect(full.other('de'), 'Sow'); // non-English reader sees the English name
    expect(full.other('en'), 'Zaaien'); // English reader sees the Dutch name
    expect(const LocalizedText(nl: 'Basilicum', en: 'Basilicum').other('en'), '');
  });

  test('json round-trips all six and tolerates two', () {
    expect(LocalizedText.fromJson(full.toJson()), full);
    expect(two.toJson(), {'nl': 'Oogst', 'en': 'Harvest'});
    final fromEnOnly = LocalizedText.fromJson({'en': 'Pots'});
    expect(fromEnOnly.nl, 'Pots');
  });
}
