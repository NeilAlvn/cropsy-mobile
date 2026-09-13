// Repository-level timeline check: adding a growing plant builds its path in
// the tasks table; logging a late node moves the future and nothing else.

import 'package:cropsy/data/frost_presets.dart';
import 'package:cropsy/data/seed.dart';
import 'package:cropsy/db/database.dart';
import 'package:cropsy/features/garden/garden_repository.dart';
import 'package:cropsy/timing/replan.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start → path; late transplant log moves harvest, keeps the past', () async {
    final repo = await GardenRepository.create(db: AppDatabase.memory(), today: demoToday);
    final gardenId = await repo.createGarden(region: defaultRegion, kind: GardenKind.balcony);
    final plantId = await repo.addPlant(
      gardenId: gardenId,
      cropSlug: 'tomato',
      potLitres: 12,
      plantedOn: '2026-03-19',
      method: MethodType.sowIndoor,
    );

    var path = await repo.pathFor(plantId);
    expect(path.map((n) => n.kind).toList(), [
      NodeKind.sow, NodeKind.potOn, NodeKind.transplant,
      NodeKind.feed, NodeKind.feed, NodeKind.feed, NodeKind.feed, NodeKind.harvest,
    ]);
    final transplant = path.firstWhere((n) => n.kind == NodeKind.transplant);
    expect(transplant.due, '2026-05-14');
    final harvestBefore = path.firstWhere((n) => n.kind == NodeKind.harvest);
    expect(harvestBefore.until, '2026-08-07'); // reconstructed from the crop, not stored

    // This week (demoToday 2026-05-13) shows the open transplant node.
    final week = await repo.thisWeek();
    expect(week.any((i) => i.taskId == transplant.id), isTrue);

    final result = await repo.logNode(plantId, transplant.id, '2026-05-28');
    expect(result.shiftDays, 14);

    path = await repo.pathFor(plantId);
    final harvest = path.firstWhere((n) => n.kind == NodeKind.harvest);
    expect(harvest.due, '2026-07-27');
    expect(harvest.plannedDue, '2026-07-13');
    expect(harvest.movedReason, isNotNull);
    expect(path.firstWhere((n) => n.kind == NodeKind.transplant).loggedOn, '2026-05-28');
    expect(path.firstWhere((n) => n.kind == NodeKind.potOn).movedReason, isNull);
    expect((await repo.plantById(plantId))!.stage, 'vegetative');

    // A logged node stays in This Week, checked off.
    expect((await repo.thisWeek()).firstWhere((i) => i.taskId == transplant.id).completed, isTrue);
    await repo.skipNode(path.firstWhere((n) => n.kind == NodeKind.feed).id,
        const LocalizedText(nl: 'Regen', en: 'Rain'));
    expect((await repo.pathFor(plantId)).where((n) => n.skipped).length, 1);

    // Stop growing clears the path; start again rebuilds it fresh.
    await repo.stopGrowing(plantId);
    expect(await repo.pathFor(plantId), isEmpty);
    await repo.startGrowing(plantId, method: MethodType.transplant);
    expect((await repo.pathFor(plantId)).first.kind, NodeKind.transplant);
    expect((await repo.daysUntilHarvest((await repo.plantById(plantId))!)), 60);

    repo.dispose();
  });
}
