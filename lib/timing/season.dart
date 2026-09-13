/// The season path (PRD §7.4): one garden, twelve months. Outdoor sow/plant
/// windows, harvest windows from the paths, and succession prompts when a
/// harvest ends while another crop's direct-sow window is still open.
///
/// Port of `src/timing/season.ts`; parity in `test/season_test.dart`.
library;

import 'dates.dart';
import 'engine.dart';
import 'types.dart';

class SeasonPlant {
  const SeasonPlant({required this.plantId, required this.cropSlug, this.harvestStart, this.harvestEnd});
  final String plantId;
  final String cropSlug;
  final String? harvestStart;
  final String? harvestEnd;
}

enum SeasonNodeKind { sowWindow, harvestWindow, succession }

const _kindWire = <SeasonNodeKind, String>{
  SeasonNodeKind.sowWindow: 'sow_window',
  SeasonNodeKind.harvestWindow: 'harvest_window',
  SeasonNodeKind.succession: 'succession',
};

class SeasonNode {
  const SeasonNode({
    required this.kind,
    required this.cropSlug,
    required this.plantId,
    required this.start,
    required this.end,
    this.afterPlantId,
    this.note,
  });
  final SeasonNodeKind kind;
  final String cropSlug;
  final String? plantId;
  final String start;
  final String end;
  final String? afterPlantId;
  final LocalizedText? note;

  Map<String, dynamic> toJson() => {
        'kind': _kindWire[kind],
        'crop_slug': cropSlug,
        'plant_id': plantId,
        'start': start,
        'end': end,
        if (afterPlantId != null) 'after_plant_id': afterPlantId,
        'note': note?.toJson(),
      };
}

class SeasonParams {
  const SeasonParams({this.minDaysLeftInWindow = 14, this.maxSuggestions = 2});
  final int minDaysLeftInWindow;
  final int maxSuggestions;
}

const defaultSeason = SeasonParams();

List<SeasonNode> seasonPath(
  List<SeasonPlant> plants,
  List<Crop> catalogue,
  FrostProfile frost, {
  SeasonParams params = defaultSeason,
}) {
  final bySlug = {for (final c in catalogue) c.slug: c};
  final nodes = <SeasonNode>[];

  for (final p in plants) {
    final crop = bySlug[p.cropSlug];
    if (crop == null) continue;
    for (final w in scheduleCrop(crop, frost)) {
      if (w.method == MethodType.sowIndoor) continue;
      nodes.add(SeasonNode(kind: SeasonNodeKind.sowWindow, cropSlug: p.cropSlug, plantId: p.plantId, start: w.start, end: w.end, note: w.note));
    }
    if (p.harvestStart != null && p.harvestEnd != null) {
      nodes.add(SeasonNode(kind: SeasonNodeKind.harvestWindow, cropSlug: p.cropSlug, plantId: p.plantId, start: p.harvestStart!, end: p.harvestEnd!));
    }
  }

  final growing = plants.map((p) => p.cropSlug).toSet();
  for (final p in plants) {
    final hEnd = p.harvestEnd;
    if (hEnd == null) continue;
    final cutoff = toIso(addDays(parseIso(hEnd), params.minDaysLeftInWindow));
    final candidates = <({Crop crop, String start, String end})>[];
    for (final crop in catalogue) {
      if (growing.contains(crop.slug)) continue;
      for (final w in scheduleCrop(crop, frost)) {
        if (w.method != MethodType.sowDirect) continue;
        if (w.start.compareTo(hEnd) <= 0 && w.end.compareTo(cutoff) >= 0) {
          candidates.add((crop: crop, start: hEnd, end: w.end));
          break;
        }
      }
    }
    candidates.sort((a, b) {
      final c = a.crop.harvestDaysMin.compareTo(b.crop.harvestDaysMin);
      return c != 0 ? c : a.crop.slug.compareTo(b.crop.slug);
    });
    for (final c in candidates.take(params.maxSuggestions)) {
      final after = bySlug[p.cropSlug];
      nodes.add(SeasonNode(
        kind: SeasonNodeKind.succession,
        cropSlug: c.crop.slug,
        plantId: null,
        afterPlantId: p.plantId,
        start: c.start,
        end: c.end,
        note: LocalizedText(
          nl: 'Plek vrij na ${after?.names.nl ?? p.cropSlug} ($hEnd) — ${c.crop.names.nl} zaaien kan nog tot ${c.end}.',
          en: 'Space frees up after ${after?.names.en ?? p.cropSlug} ($hEnd) — ${c.crop.names.en} can still be sown until ${c.end}.',
        ),
      ));
    }
  }

  nodes.sort((a, b) {
    var c = a.start.compareTo(b.start);
    if (c != 0) return c;
    c = _kindWire[a.kind]!.compareTo(_kindWire[b.kind]!);
    return c != 0 ? c : a.cropSlug.compareTo(b.cropSlug);
  });
  return nodes;
}
