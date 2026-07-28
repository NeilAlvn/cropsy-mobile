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
import 'weather_adjust.dart';

/// Days between waterings for a given pot size (litres). null = in-ground.
int wateringIntervalDays(int? potLitres) {
  if (potLitres == null) return 4; // in-ground / bed
  if (potLitres <= 5) return 1; // a 3 L herb pot on a hot balcony
  if (potLitres <= 12) return 2;
  return 3;
}

/// Watering tasks for one plant across `[today, today + horizonDays)`.
List<Task> wateringTasksFor({
  required String plantId,
  required String cropSlug,
  required int? potLitres,
  required String today,
  int horizonDays = 7,
}) {
  final interval = wateringIntervalDays(potLitres);
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
