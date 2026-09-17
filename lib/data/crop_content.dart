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

/// When the first harvest lands, from the engine's own windows. Null when the
/// crop has no window in this region.
String? firstHarvestDate(Crop crop, FrostProfile frost) {
  final windows = scheduleCrop(crop, frost);
  final establish = windows.isEmpty
      ? null
      : (windows.map((w) => parseIso(w.start)).reduce((a, b) => a.isBefore(b) ? a : b));
  final harvest = establish?.add(Duration(days: crop.harvestDaysMin.toInt()));

  return harvest == null ? null : toIso(harvest);
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
