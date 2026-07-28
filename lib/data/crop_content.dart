/// Placeholder editorial content for the rich crop detail (soil prep, how-tos,
/// benefits, FAQ). The crop data doesn't carry this yet, so this generates
/// sensible generic copy — some of it keyed off real fields (spacing, sun,
/// harvest days) so it reads specific. Clearly prototype content to replace with
/// real horticultural copy later.
library;

import '../timing/dates.dart';
import '../timing/engine.dart';
import '../timing/types.dart';

/// One stage on the growth timeline, with a real date derived from the engine.
class GrowthStage {
  const GrowthStage(this.emoji, this.title, this.detail, this.date);
  final String emoji;
  final String title;
  final String detail;
  final String? date; // ISO, may be null
}

class HowToStage {
  const HowToStage(this.emoji, this.title, this.rows);
  final String emoji;
  final String title;

  /// (label, value) pairs.
  final List<(String, String)> rows;
}

class Faq {
  const Faq(this.q, this.a);
  final String q;
  final String a;
}

/// One column on the horizontal day-staged growth strip (GrowIt-style):
/// Starting → Sprout → Harvest, each with a day range.
class TimelineStage {
  const TimelineStage(this.emoji, this.label, this.dayRange);
  final String emoji;
  final String label;
  final String dayRange;
}

/// A nutrition row for the Benefits table (per 100 g). Prototype figures.
class Nutrient {
  const Nutrient(this.label, this.value, {this.percent});
  final String label;
  final String value;
  final String? percent;
}

/// Growth timeline: sow → plant out → harvest, with real dates from the engine.
List<GrowthStage> growthTimeline(Crop crop, FrostProfile frost) {
  final windows = scheduleCrop(crop, frost);
  String? firstOf(bool Function(MethodType) test) {
    final ws = windows.where((w) => test(w.method)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return ws.isEmpty ? null : ws.first.start;
  }

  final sow = firstOf((m) => m == MethodType.sowIndoor || m == MethodType.sowDirect);
  final plantOut =
      firstOf((m) => m == MethodType.transplant || m == MethodType.plant);
  final establish = windows.isEmpty
      ? null
      : (windows.map((w) => parseIso(w.start)).reduce((a, b) => a.isBefore(b) ? a : b));
  final harvest = establish?.add(Duration(days: crop.harvestDaysMin.toInt()));

  return [
    GrowthStage('🌱', 'Sow', 'Start the seeds off.', sow),
    if (plantOut != null)
      GrowthStage('🌿', 'Plant out', 'Move outside once it’s warm enough.', plantOut),
    GrowthStage('🌸', 'Grow on', 'Water, feed and watch it fill out.', null),
    GrowthStage('🧺', 'Harvest', 'Roughly ${crop.harvestDaysMin}–${crop.harvestDaysMax} days after sowing.',
        harvest == null ? null : toIso(harvest)),
  ];
}

/// GrowIt-style horizontal day-staged strip. Day ranges scale with the crop's
/// real harvest window so they read specific.
List<TimelineStage> timelineStages(Crop crop) {
  final sprout = (crop.harvestDaysMin * 0.15).round();
  return [
    const TimelineStage('🌰', 'Starting', 'Day 1'),
    TimelineStage('🌱', 'Sprout', 'Day ${sprout <= 0 ? 5 : sprout}–${sprout + 4}'),
    TimelineStage('🧺', 'Harvest', 'Day ${crop.harvestDaysMin}–${crop.harvestDaysMax}'),
  ];
}

/// Soil type suitability (GrowIt lists this alongside pH). Generic prototype set.
String soilType(Crop crop) => switch (crop.category) {
      'root' || 'potato' => 'Sandy, Loam, Sandy loam (light & free-draining)',
      'brassica' => 'Loam, Clay loam (firm, fertile)',
      'legume' => 'Loam, Sandy loam',
      'leafy' || 'herb' => 'Loam, Sandy loam, Chalky',
      _ => 'Sand, Loam, Chalky, Clay, Sandy loam',
    };

String soilPh(Crop crop) => switch (crop.category) {
      'brassica' => '6.5–7.5',
      'root' || 'potato' => '5.5–6.5',
      'legume' => '6.0–7.0',
      _ => '6.0–7.0',
    };

/// Prototype nutrition table (per 100 g). Rough, editable figures per category.
List<Nutrient> nutrition(Crop crop) {
  final (kcal, carbs, fibre, vitc) = switch (crop.category) {
    'leafy' || 'herb' => ('23 kcal', '3.6 g', '2.2 g', '28 mg'),
    'root' => ('41 kcal', '9.6 g', '2.8 g', '6 mg'),
    'potato' => ('77 kcal', '17 g', '2.2 g', '20 mg'),
    'legume' => ('81 kcal', '14 g', '5.4 g', '40 mg'),
    'fruit-veg' || 'fruit' => ('18 kcal', '3.9 g', '1.2 g', '14 mg'),
    'brassica' => ('34 kcal', '7 g', '2.6 g', '89 mg'),
    _ => ('30 kcal', '6 g', '2 g', '20 mg'),
  };
  return [
    const Nutrient('Portion size', '100 g'),
    Nutrient('Calories', kcal),
    Nutrient('Carbohydrates', carbs, percent: '≈5%'),
    Nutrient('Fibre', fibre, percent: '≈10%'),
    Nutrient('Vitamin C', vitc, percent: '≈25%'),
  ];
}

String soilPrep(Crop crop) {
  final ph = switch (crop.category) {
    'brassica' => '6.5–7.5 (sweeten acidic soil with a little lime)',
    'root' || 'potato' => '5.5–6.5',
    'legume' => '6.0–7.0 (they fix their own nitrogen — go easy on feed)',
    _ => '6.0–7.0',
  };
  final pot = crop.containerOk && crop.minPotLitres != null
      ? ' In containers, use at least a ${crop.minPotLitres} L pot of fresh, '
          'peat-free multipurpose compost with drainage holes.'
      : '';
  return 'Prefers a well-drained, fertile soil, pH $ph. Work in a bucket of '
      'garden compost before planting and rake to a fine tilth.$pot';
}

List<HowToStage> howTos(Crop crop) {
  final depth = switch (crop.category) {
    'legume' => '3–5 cm',
    'root' || 'potato' || 'allium' => '2–4 cm',
    _ => '5–10 mm',
  };
  final water = (crop.minPotLitres ?? 99) <= 5 ? 'Daily in warm weather' : 'Every 2–3 days';
  return [
    HowToStage('🌱', 'Starting', [
      ('Methods', crop.methods.map((m) => methodToWire(m.type).replaceAll('_', ' ')).join(' · ')),
      ('Spacing', '${crop.spacingCm} cm apart'),
      ('Depth', depth),
      ('Water', water),
    ]),
    const HowToStage('🌿', 'Seedling', [
      ('Transplanting', 'Move on once it has 2–4 true leaves and the frosts have passed'),
      ('Hardening off', 'Acclimatise outdoors over 7–10 days first'),
    ]),
    HowToStage('🧺', 'Harvest', [
      ('When', '${crop.harvestDaysMin}–${crop.harvestDaysMax} days after sowing'),
      ('Tip', 'Pick regularly to keep it productive'),
    ]),
  ];
}

String benefits(Crop crop) => switch (crop.category) {
      'herb' => 'Fresh ${crop.names.en.toLowerCase()} lifts everyday cooking and is '
          'far cheaper (and tastier) grown at home than shop-bought bunches.',
      'leafy' => 'Cut-and-come-again leaves give you weeks of salad from a single '
          'sowing — rich in folate and vitamin K.',
      'fruit-veg' || 'fruit' => 'Home-grown ${crop.names.en.toLowerCase()} beats the '
          'supermarket on flavour and vitamin C, picked at peak ripeness.',
      'legume' => 'A good source of plant protein and fibre — and the plants feed '
          'your soil with nitrogen as they grow.',
      'root' => 'Stores well, packed with fibre and slow-release energy, and takes '
          'up little space.',
      _ => 'A rewarding, nutritious crop that’s well suited to a small space.',
    };

List<Faq> faqs(Crop crop) {
  final sun = crop.sun == 'full' ? 'a sunny spot (6+ hours)' : 'sun or light shade';
  return [
    Faq('Can I grow ${crop.names.en.toLowerCase()} in a pot?',
        crop.containerOk
            ? 'Yes — use at least a ${crop.minPotLitres ?? 10} L container in $sun.'
            : 'It does best in open ground, but a large deep container can work.'),
    Faq('How much sun does it need?',
        'It prefers $sun.'),
    Faq('How long until I can harvest?',
        'Around ${crop.harvestDaysMin}–${crop.harvestDaysMax} days from sowing, depending on the weather.'),
    Faq('When should I plant it?',
        'The planting calendar above is tuned to your region’s frost dates — follow the green band.'),
  ];
}
