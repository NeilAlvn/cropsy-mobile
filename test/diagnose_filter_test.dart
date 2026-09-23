import 'package:cropsy/features/diagnose/diagnose_screen.dart';
import 'package:cropsy/timing/content_snapshot.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

Problem _problem({
  required String slug,
  required LocalizedText names,
  required List<String> parts,
  LocalizedText symptoms = const LocalizedText(nl: '', en: ''),
  List<String> affects = const [],
}) =>
    Problem(
      slug: slug,
      names: names,
      kind: 'pest',
      parts: parts,
      symptoms: symptoms,
      treatment: const LocalizedText(nl: '', en: ''),
      prevention: const LocalizedText(nl: '', en: ''),
      affects: affects,
      image: null,
    );

void main() {
  final aphids = _problem(
    slug: 'aphids',
    names: const LocalizedText(nl: 'Bladluis', en: 'Aphids'),
    parts: ['leaves', 'stems'],
    symptoms: const LocalizedText(nl: 'Kleverige blaadjes', en: 'Sticky leaves'),
    affects: ['tomato'],
  );
  final blight = _problem(
    slug: 'blight',
    names: const LocalizedText(nl: 'Aardappelziekte', en: 'Late blight'),
    parts: ['leaves'],
    symptoms: const LocalizedText(nl: 'Bruine vlekken', en: 'Brown spots'),
    affects: ['potato'],
  );
  final rootRot = _problem(
    slug: 'root-rot',
    names: const LocalizedText(nl: 'Wortelrot', en: 'Root rot'),
    parts: ['roots'],
    affects: ['tomato'],
  );
  final all = [aphids, blight, rootRot];

  LocalizedText cropNames(String slug) => switch (slug) {
        'tomato' => const LocalizedText(nl: 'Tomaat', en: 'Tomato'),
        'potato' => const LocalizedText(nl: 'Aardappel', en: 'Potato'),
        _ => LocalizedText(nl: slug, en: slug),
      };

  List<String> slugs(List<Problem> p) => p.map((x) => x.slug).toList();

  List<Problem> filter({String? part, String query = ''}) =>
      filterProblems(all, part: part, query: query, cropNames: cropNames);

  test('an empty query changes nothing, with or without a part', () {
    expect(slugs(filter()), ['aphids', 'blight', 'root-rot']);
    expect(slugs(filter(query: '   ')), ['aphids', 'blight', 'root-rot']);
    expect(slugs(filter(part: 'leaves')), ['aphids', 'blight']);
  });

  test('the query composes with the part instead of replacing it', () {
    // "tomato" also hits root rot, but the leaves chip must hold.
    expect(slugs(filter(part: 'leaves', query: 'tomato')), ['aphids']);
    expect(slugs(filter(query: 'tomato')), ['aphids', 'root-rot']);
  });

  test('either language finds the thing, whichever side is displayed', () {
    expect(slugs(filter(query: 'aphid')), ['aphids']);
    expect(slugs(filter(query: 'bladluis')), ['aphids']);
    // Through an affected crop's name, in the other language too.
    expect(slugs(filter(query: 'aardappel')), ['blight']);
    // And through the symptoms.
    expect(slugs(filter(query: 'brown spots')), ['blight']);
  });

  test('case and surrounding whitespace do not matter', () {
    expect(slugs(filter(query: '  BLADLUIS ')), ['aphids']);
  });

  test('nothing matching gives an empty list, not everything', () {
    expect(filter(query: 'courgette'), isEmpty);
    expect(filter(part: 'roots', query: 'aphid'), isEmpty);
  });
}
