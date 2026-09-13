/// Parsing for the bundled content snapshot (`assets/data/content-snapshot.json`
/// = `GET /api/content`, PRD §8.1): collections, monthly checklist, prices.
library;

import 'dart:convert';

import 'types.dart';

class ContentCollection {
  const ContentCollection({required this.slug, required this.title, required this.intro, required this.cropSlugs, required this.image});
  final String slug;
  final LocalizedText title;
  final LocalizedText intro;
  final List<String> cropSlugs;
  final String? image;
}

class ChecklistItem {
  const ChecklistItem({required this.month, required this.title, required this.body, required this.link});
  final int month;
  final LocalizedText title;
  final LocalizedText body;
  final String? link;
}

class Price {
  const Price({required this.cropSlug, required this.eur, required this.unit});
  final String cropSlug;
  final double eur;

  /// 'kg' | 'pcs'
  final String unit;
}

class ContentSnapshot {
  const ContentSnapshot({required this.version, required this.collections, required this.checklist, required this.prices});
  final String version;
  final List<ContentCollection> collections;
  final List<ChecklistItem> checklist;
  final Map<String, Price> prices;

  static const empty = ContentSnapshot(version: '', collections: [], checklist: [], prices: {});

  factory ContentSnapshot.fromJson(Map<String, dynamic> j) => ContentSnapshot(
        version: j['version'] as String,
        collections: [
          for (final c in (j['collections'] as List? ?? const []).cast<Map<String, dynamic>>())
            ContentCollection(
              slug: c['slug'] as String,
              title: LocalizedText.fromJson(c['title'] as Map<String, dynamic>),
              intro: LocalizedText.fromJson(c['intro'] as Map<String, dynamic>),
              cropSlugs: (c['crop_slugs'] as List).cast<String>(),
              image: c['image'] as String?,
            ),
        ],
        checklist: [
          for (final c in (j['monthly_checklist'] as List? ?? const []).cast<Map<String, dynamic>>())
            ChecklistItem(
              month: (c['month'] as num).toInt(),
              title: LocalizedText.fromJson(c['title'] as Map<String, dynamic>),
              body: LocalizedText.fromJson(c['body'] as Map<String, dynamic>),
              link: c['link'] as String?,
            ),
        ],
        prices: {
          for (final p in (j['prices'] as List? ?? const []).cast<Map<String, dynamic>>())
            p['crop_slug'] as String: Price(
              cropSlug: p['crop_slug'] as String,
              eur: (p['eur'] as num).toDouble(),
              unit: p['unit'] as String,
            ),
        },
      );

  static ContentSnapshot parse(String jsonText) => ContentSnapshot.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
}
