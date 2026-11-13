/// The growth timeline for the crop page: the stages, with real dates derived
/// from the engine. The editorial sections come from the content snapshot, in
/// the reader's language; nothing here generates prose.
library;

import '../timing/dates.dart';
import '../timing/engine.dart';
import '../timing/types.dart';
import '../l10n/strings.dart';

/// One column on the horizontal day-staged growth strip (GrowIt-style):
/// Starting → Sprout → Harvest, each with a day range.
class TimelineStage {
  const TimelineStage(this.emoji, this.label, this.dayRange);
  final String emoji;
  final LocalizedText label;
  final LocalizedText dayRange;
}

/// Harvest spans, one per outdoor window (plant out, plant, sow direct):
/// window start + harvest days_min .. window end + harvest days_max. Harvest
/// days count from planting out, so indoor sowing never anchors a harvest.
List<({DateTime start, DateTime end})> harvestSpans(Crop crop, FrostProfile frost) => [
      for (final w in scheduleCrop(crop, frost))
        if (w.method != MethodType.sowIndoor)
          (
            start: parseIso(w.start).add(Duration(days: crop.harvestDaysMin.toInt())),
            end: parseIso(w.end).add(Duration(days: crop.harvestDaysMax.toInt())),
          ),
    ];

/// When the first harvest lands, from the engine's own windows. Null when the
/// crop has no outdoor window in this region.
String? firstHarvestDate(Crop crop, FrostProfile frost) {
  final spans = harvestSpans(crop, frost);
  if (spans.isEmpty) return null;
  return toIso(spans.map((s) => s.start).reduce((a, b) => a.isBefore(b) ? a : b));
}

/// GrowIt-style horizontal day-staged strip. Day ranges scale with the crop's
/// real harvest window so they read specific.
List<TimelineStage> timelineStages(Crop crop) {
  final sprout = (crop.harvestDaysMin * 0.15).round();
  final firstLeaf = sprout <= 0 ? 5 : sprout;
  return [
    TimelineStage('🌰', Str.stageStarting, Str.dayOne),
    TimelineStage('🌱', Str.stageSprout, Str.dayRange(firstLeaf, firstLeaf + 4)),
    TimelineStage('🧺', Str.harvest,
        Str.dayRange(crop.harvestDaysMin, crop.harvestDaysMax)),
  ];
}
