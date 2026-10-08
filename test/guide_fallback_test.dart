import 'package:cropsy/timing/content_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

Guide _guide(String lang) => Guide(
      cropSlug: 'basil',
      lang: lang,
      starting: '', seedling: '', vegetative: '', flowering: '', harvest: '',
      faq: const [], benefits: '', sources: const [],
    );

ContentSnapshot _with(List<Guide> guides) => ContentSnapshot(
      version: 't', collections: const [], checklist: const [], prices: const {}, guides: guides,
    );

void main() {
  test('a German reader gets the English guide, never the Dutch one', () {
    final content = _with([_guide('nl'), _guide('en')]);
    expect(content.guideFor('basil', lang: 'de')!.lang, 'en');
    expect(content.guideFor('basil', lang: 'nl')!.lang, 'nl');
  });

  test('Dutch is the last resort when English is missing', () {
    final content = _with([_guide('nl')]);
    expect(content.guideFor('basil', lang: 'fr')!.lang, 'nl');
  });

  test('a guide in the reader language wins over English', () {
    final content = _with([_guide('en'), _guide('de')]);
    expect(content.guideFor('basil', lang: 'de')!.lang, 'de');
  });
}
