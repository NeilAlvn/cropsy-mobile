/// Themed crop collections for the Explore tab — GrowIt groups crops by use-case;
/// ours lean into the container/balcony wedge. Membership is derived from the
/// crop data, so it stays correct as the catalogue changes.
library;

import '../timing/types.dart';
import 'crop_derived.dart';

class Collection {
  const Collection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.crops,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<Crop> crops;

  String? get coverSlug => crops.isEmpty ? null : crops.first.slug;
}

const _scrapSlugs = {
  'lettuce', 'spring-onion', 'garlic', 'celery', 'chives', 'fennel', 'pak-choi',
};

List<Collection> buildCollections(List<Crop> all) {
  Collection make(String id, String title, String subtitle, bool Function(Crop) test) =>
      Collection(
        id: id,
        title: title,
        subtitle: subtitle,
        crops: all.where(test).toList()..sort((a, b) => a.names.en.compareTo(b.names.en)),
      );

  return [
    make('balconies', 'Best for balconies', 'Thrives in a pot on a sunny ledge',
        (c) => c.containerOk && (c.minPotLitres ?? 99) <= 10),
    make('fast', 'Fast harvests', 'Something to pick in weeks, not months',
        (c) => c.harvestDaysMin <= 60),
    make('herbs', 'Windowsill herbs', 'Fresh flavour within arm’s reach',
        (c) => c.category == 'herb' && c.containerOk),
    make('easy', 'Easy to grow', 'Forgiving crops for a first season',
        (c) => difficultyOf(c) == Difficulty.easy),
    make('scraps', 'Regrow from scraps', 'Start again from the kitchen',
        (c) => _scrapSlugs.contains(c.slug)),
    make('sun', 'Full-sun lovers', 'For the brightest spot you’ve got',
        (c) => c.sun == 'full'),
  ].where((c) => c.crops.isNotEmpty).toList();
}
