// Prototype integration test — exercises the real data layer end to end without
// rendering widgets (the UI uses google_fonts, which does a runtime fetch that
// hangs under `flutter test`). Engine + DB parity are covered by their own tests;
// this proves the GardenRepository wires them together correctly.

import 'package:cropsy/features/garden/garden_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // rootBundle asset loading (crops-snapshot.json) needs the test binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo garden → This Week has tasks + a weather hint; complete + harvest',
      () async {
    final repo = await GardenRepository.create();
    await repo.seedDemoGarden();

    final items = await repo.thisWeek();
    expect(items, isNotEmpty, reason: 'seeded plants should produce tasks');
    expect(items.any((i) => i.hint != null), isTrue,
        reason: 'the sample forecast should trigger at least one weather hint');

    // Completing a task sticks.
    final first = items.first;
    await repo.setTaskCompleted(first.taskId, true);
    final after = await repo.thisWeek();
    expect(
      after.firstWhere((i) => i.taskId == first.taskId).completed,
      isTrue,
    );

    // Harvest tally (F7).
    await repo.logHarvest(cropSlug: 'tomato', amount: '6', valueEuros: 4.5);
    await repo.logHarvest(cropSlug: 'courgette', amount: '2', valueEuros: 1.5);
    expect(await repo.seasonHarvestValue(), 6.0);

    repo.dispose();
  });

  test('crop catalogue loads all 60 verified crops from the bundled snapshot',
      () async {
    final repo = await GardenRepository.create();
    expect(repo.crops, hasLength(60));
    expect(repo.cropVersion, isNotEmpty);
    repo.dispose();
  });
}
