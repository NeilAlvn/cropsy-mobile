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

class Variety {
  const Variety({required this.slug, required this.cropSlug, required this.names, required this.daysMin, required this.daysMax, required this.containerOk, required this.suppliers, required this.traits});
  final String slug;
  final String cropSlug;
  final LocalizedText names;
  final int? daysMin;
  final int? daysMax;
  final bool containerOk;
  final List<String> suppliers;
  final List<String> traits;
}

class CompanionPair {
  const CompanionPair({required this.a, required this.b, required this.reason});
  final String a;
  final String b;
  final LocalizedText reason;
  bool involves(String x, String y) => (a == x && b == y) || (a == y && b == x);
}

class Problem {
  const Problem({required this.slug, required this.names, required this.kind, required this.parts, required this.symptoms, required this.treatment, required this.prevention, required this.affects, required this.image});
  final String slug;
  final LocalizedText names;

  /// pest | disease | disorder
  final String kind;

  /// whole | leaves | stems | flowers | fruits | roots
  final List<String> parts;
  final LocalizedText symptoms;
  final LocalizedText treatment;
  final LocalizedText prevention;
  final List<String> affects;
  final String? image;
}

class ContentSnapshot {
  const ContentSnapshot({
    required this.version,
    required this.collections,
    required this.checklist,
    required this.prices,
    this.varieties = const [],
    this.goodCompanions = const [],
    this.badCompanions = const [],
    this.problems = const [],
  });
  final String version;
  final List<ContentCollection> collections;
  final List<ChecklistItem> checklist;
  final Map<String, Price> prices;
  final List<Variety> varieties;
  final List<CompanionPair> goodCompanions;
  final List<CompanionPair> badCompanions;
  final List<Problem> problems;

  static const empty = ContentSnapshot(version: '', collections: [], checklist: [], prices: {});

  List<Variety> varietiesOf(String cropSlug) => varieties.where((v) => v.cropSlug == cropSlug).toList();

  /// Bad pairing between two crops, if the verified matrix lists one.
  CompanionPair? conflict(String a, String b) {
    for (final p in badCompanions) {
      if (p.involves(a, b)) return p;
    }
    return null;
  }

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
        varieties: [
          for (final v in (j['varieties'] as List? ?? const []).cast<Map<String, dynamic>>())
            Variety(
              slug: v['slug'] as String,
              cropSlug: v['crop_slug'] as String,
              names: LocalizedText.fromJson(v['names'] as Map<String, dynamic>),
              daysMin: ((v['days_to_harvest'] as Map<String, dynamic>?)?['min'] as num?)?.toInt(),
              daysMax: ((v['days_to_harvest'] as Map<String, dynamic>?)?['max'] as num?)?.toInt(),
              containerOk: v['container_ok'] as bool? ?? true,
              suppliers: (v['suppliers'] as List? ?? const []).cast<String>(),
              traits: (v['traits'] as List? ?? const []).cast<String>(),
            ),
        ],
        goodCompanions: _pairs((j['companions'] as Map<String, dynamic>?)?['good']),
        badCompanions: _pairs((j['companions'] as Map<String, dynamic>?)?['bad']),
        problems: [
          for (final p in (j['problems'] as List? ?? const []).cast<Map<String, dynamic>>())
            Problem(
              slug: p['slug'] as String,
              names: LocalizedText.fromJson(p['names'] as Map<String, dynamic>),
              kind: p['kind'] as String,
              parts: (p['parts'] as List).cast<String>(),
              symptoms: LocalizedText.fromJson(p['symptoms'] as Map<String, dynamic>),
              treatment: LocalizedText.fromJson(p['treatment'] as Map<String, dynamic>),
              prevention: LocalizedText.fromJson(p['prevention'] as Map<String, dynamic>),
              affects: (p['affects'] as List).cast<String>(),
              image: p['image'] as String?,
            ),
        ],
      );

  static List<CompanionPair> _pairs(Object? raw) => [
        for (final p in (raw as List? ?? const []).cast<Map<String, dynamic>>())
          CompanionPair(a: p['a'] as String, b: p['b'] as String, reason: LocalizedText.fromJson(p['reason'] as Map<String, dynamic>)),
      ];

  static ContentSnapshot parse(String jsonText) => ContentSnapshot.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
}
