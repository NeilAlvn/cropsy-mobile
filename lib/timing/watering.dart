/// Client-side watering-task generation.
///
/// Watering is recurring and driven by pot size + weather, not frost — so it is
/// NOT part of the frost-relative base schedule, and (as agreed with the
/// backend) the client owns it: we generate the watering cadence here and the
/// server's weather-adjust only ever *moves or skips* what we give it.
///
/// Cadence heuristic (first pass): smaller pots dry out faster, so they get a
/// shorter interval. In-ground / large beds get the longest.
library;

import 'dates.dart';
import 'types.dart';
import 'weather_adjust.dart';

/// Smaller pots dry out faster. A 3 L herb pot on a hot balcony is daily work;
/// a bed holds water for days. Mirrors DEFAULT_WATER_CADENCE in watering.ts.
const defaultWaterCadence =
    WaterCadence(small: 1, medium: 2, large: 3, ground: 4);

/// Days between waterings for a given pot size (litres). null = in-ground.
/// [cadence] is the crop's override (`Crop.waterCadenceDays`), if any.
int wateringIntervalDays(int? potLitres, {WaterCadence? cadence}) {
  final c = cadence ?? defaultWaterCadence;
  if (potLitres == null) return c.ground;
  if (potLitres <= 5) return c.small;
  if (potLitres <= 12) return c.medium;
  return c.large;
}

/// Watering tasks for one plant across `[today, today + horizonDays)`.
List<Task> wateringTasksFor({
  required String plantId,
  required String cropSlug,
  required int? potLitres,
  required String today,
  int horizonDays = 7,
  WaterCadence? cadence,
}) {
  final interval = wateringIntervalDays(potLitres, cadence: cadence);
  final from = parseIso(today);
  final tasks = <Task>[];
  for (var d = 0; d < horizonDays; d += interval) {
    final due = toIso(addDays(from, d));
    tasks.add(Task(
      id: 'water-$plantId-$due',
      cropSlug: cropSlug,
      kind: TaskKind.water,
      due: due,
    ));
  }
  return tasks;
}
