/// Shared types for the crop rules and the schedule they produce.
///
/// A direct port of the backend's `src/timing/types.ts`. The Flutter client
/// evaluates the same crop objects the server bundles into
/// `crops-snapshot.json`, so this stays plain-data and framework-free.
library;

enum MethodType { sowIndoor, sowDirect, transplant, plant }

const _methodFromWire = <String, MethodType>{
  'sow_indoor': MethodType.sowIndoor,
  'sow_direct': MethodType.sowDirect,
  'transplant': MethodType.transplant,
  'plant': MethodType.plant,
};
const _methodToWire = <MethodType, String>{
  MethodType.sowIndoor: 'sow_indoor',
  MethodType.sowDirect: 'sow_direct',
  MethodType.transplant: 'transplant',
  MethodType.plant: 'plant',
};

MethodType methodFromWire(String s) {
  final m = _methodFromWire[s];
  if (m == null) throw ArgumentError('unknown method type: $s');
  return m;
}

String methodToWire(MethodType m) => _methodToWire[m]!;

enum FrostAnchor { lastFrost, firstFrost }

FrostAnchor anchorFromWire(String s) => switch (s) {
      'last_frost' => FrostAnchor.lastFrost,
      'first_frost' => FrostAnchor.firstFrost,
      _ => throw ArgumentError('unknown frost anchor: $s'),
    };

/// A short piece of text with Dutch + English variants. Both are always present.
class LocalizedText {
  const LocalizedText({required this.nl, required this.en});

  final String nl;
  final String en;

  factory LocalizedText.fromJson(Map<String, dynamic> j) =>
      LocalizedText(nl: j['nl'] as String, en: j['en'] as String);

  Map<String, dynamic> toJson() => {'nl': nl, 'en': en};

  @override
  bool operator ==(Object other) =>
      other is LocalizedText && other.nl == nl && other.en == en;

  @override
  int get hashCode => Object.hash(nl, en);
}

/// One way to grow a crop, timed relative to a frost anchor.
class CropMethod {
  const CropMethod({
    required this.type,
    required this.anchor,
    required this.startWeeks,
    required this.endWeeks,
    required this.minSoilC,
    required this.note,
  });

  final MethodType type;
  final FrostAnchor anchor;

  /// Week offset from the anchor for the START of the window (negative = before).
  final num startWeeks;

  /// Week offset from the anchor for the END of the window.
  final num endWeeks;

  /// Don't act below this soil/air temp; the weather layer gates it. null = ignore.
  final num? minSoilC;
  final LocalizedText? note;

  factory CropMethod.fromJson(Map<String, dynamic> j) => CropMethod(
        type: methodFromWire(j['type'] as String),
        anchor: anchorFromWire(j['anchor'] as String),
        startWeeks: j['start_weeks'] as num,
        endWeeks: j['end_weeks'] as num,
        minSoilC: j['min_soil_c'] as num?,
        note: j['note'] == null
            ? null
            : LocalizedText.fromJson(j['note'] as Map<String, dynamic>),
      );
}

/// A crop and every way to grow it. Frost-relative data the client evaluates.
class Crop {
  const Crop({
    required this.slug,
    required this.names,
    required this.category,
    required this.frostTender,
    required this.containerOk,
    required this.minPotLitres,
    required this.spacingCm,
    required this.vakPerM2,
    required this.sun,
    required this.methods,
    required this.harvestDaysMin,
    required this.harvestDaysMax,
    required this.sources,
    required this.verified,
  });

  final String slug;
  final LocalizedText names;
  final String category;
  final bool frostTender;
  final bool containerOk;
  final num? minPotLitres;
  final num spacingCm;
  final num? vakPerM2;
  final String sun;
  final List<CropMethod> methods;
  final num harvestDaysMin;
  final num harvestDaysMax;
  final List<String> sources;
  final bool verified;

  factory Crop.fromJson(Map<String, dynamic> j) {
    final harvest = j['harvest'] as Map<String, dynamic>;
    return Crop(
      slug: j['slug'] as String,
      names: LocalizedText.fromJson(j['names'] as Map<String, dynamic>),
      category: j['category'] as String,
      frostTender: j['frost_tender'] as bool,
      containerOk: j['container_ok'] as bool,
      minPotLitres: j['min_pot_litres'] as num?,
      spacingCm: j['spacing_cm'] as num,
      vakPerM2: j['vak_per_m2'] as num?,
      sun: j['sun'] as String,
      methods: (j['methods'] as List)
          .map((m) => CropMethod.fromJson(m as Map<String, dynamic>))
          .toList(growable: false),
      harvestDaysMin: harvest['days_min'] as num,
      harvestDaysMax: harvest['days_max'] as num,
      sources:
          (j['sources'] as List).map((s) => s as String).toList(growable: false),
      verified: j['verified'] as bool,
    );
  }
}

/// The two dates that turn frost-relative rules into real calendar windows.
class FrostProfile {
  const FrostProfile({required this.lastFrost, required this.firstFrost});

  /// Average last spring frost for the user's location (ISO `yyyy-mm-dd`).
  final String lastFrost;

  /// Average first autumn frost (ISO `yyyy-mm-dd`).
  final String firstFrost;

  factory FrostProfile.fromJson(Map<String, dynamic> j) => FrostProfile(
        lastFrost: j['last_frost'] as String,
        firstFrost: j['first_frost'] as String,
      );
}

/// A concrete, dated window the app can show and remind on.
class ScheduledWindow {
  const ScheduledWindow({
    required this.cropSlug,
    required this.method,
    required this.start,
    required this.end,
    required this.minSoilC,
    required this.note,
  });

  final String cropSlug;
  final MethodType method;

  /// Inclusive window start (ISO `yyyy-mm-dd`).
  final String start;

  /// Inclusive window end (ISO `yyyy-mm-dd`).
  final String end;

  /// Soil-temp gate carried through so the weather layer can defer it.
  final num? minSoilC;
  final LocalizedText? note;

  Map<String, dynamic> toJson() => {
        'crop_slug': cropSlug,
        'method': methodToWire(method),
        'start': start,
        'end': end,
        'min_soil_c': minSoilC,
        'note': note?.toJson(),
      };
}
