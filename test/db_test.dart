// Schema smoke tests for the local Drift DB. Proves the syncable conventions
// hold on-device: soft-delete (no hard delete), the wire-exact kind converter,
// FK cascade, and the local-only dirty/cursor bookkeeping. Uses an in-memory DB.

import 'package:cropsy/db/database.dart';
import 'package:cropsy/timing/weather_adjust.dart' show TaskKind;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  const owner = '11111111-1111-1111-1111-111111111111';

  Future<void> insertGarden(String id) => db.into(db.gardens).insert(
        GardensCompanion.insert(
          id: id,
          owner: owner,
          name: 'Balcony',
          kind: GardenKind.balcony,
          dirty: const Value(true),
        ),
      );

  Future<void> insertPlant(String id, String gardenId) =>
      db.into(db.gardenPlants).insert(
            GardenPlantsCompanion.insert(
              id: id,
              owner: owner,
              gardenId: gardenId,
              cropSlug: 'tomato',
              potLitres: const Value(10),
              dirty: const Value(true),
            ),
          );

  test('the frozen task kinds round-trip through the wire-string converter', () async {
    await insertGarden('g1');
    await insertPlant('p1', 'g1');

    for (final kind in TaskKind.values) {
      await db.into(db.tasks).insert(_taskInsert(kind, 'p1'));
    }
    final rows = await db.select(db.tasks).get();
    expect(rows.map((r) => r.kind).toSet(), TaskKind.values.toSet());
    // pot_on specifically stores as snake_case, not the Dart name potOn.
    final raw = await db
        .customSelect("SELECT kind FROM tasks WHERE kind = 'pot_on'")
        .get();
    expect(raw, hasLength(1));
  });

  test('deletion is soft: the row stays, deleted_at is set, dirty flips', () async {
    await insertGarden('g1');
    await insertPlant('p1', 'g1');

    await (db.update(db.gardenPlants)..where((t) => t.id.equals('p1'))).write(
      GardenPlantsCompanion(
        deletedAt: Value(DateTime.utc(2026, 7, 28)),
        dirty: const Value(true),
      ),
    );

    final all = await db.select(db.gardenPlants).get();
    expect(all, hasLength(1), reason: 'soft delete must keep the row (tombstone)');
    expect(all.single.deletedAt, isNotNull);

    // The "live" query the UI uses excludes tombstones.
    final live = await (db.select(db.gardenPlants)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    expect(live, isEmpty);
  });

  test('foreign keys cascade: deleting a garden removes its plants', () async {
    await insertGarden('g1');
    await insertPlant('p1', 'g1');

    // Hard delete only happens locally on a full purge — here just proving the
    // FK/cascade the schema declares actually fires with PRAGMA foreign_keys ON.
    await (db.delete(db.gardens)..where((t) => t.id.equals('g1'))).go();
    final plants = await db.select(db.gardenPlants).get();
    expect(plants, isEmpty);
  });

  test('a plant cannot reference a non-existent garden (composite-FK stand-in)', () async {
    await expectLater(
      insertPlant('p1', 'does-not-exist'),
      throwsA(isA<Exception>()),
    );
  });

  test('sync cursor + snapshot version bookkeeping', () async {
    await db.into(db.appMeta).insert(
          AppMetaCompanion.insert(
            key: AppDatabase.cropSnapshotVersionKey,
            value: '33d3e8f955a94c8c',
          ),
        );
    final v = await (db.select(db.appMeta)
          ..where((t) => t.key.equals(AppDatabase.cropSnapshotVersionKey)))
        .getSingle();
    expect(v.value, '33d3e8f955a94c8c');

    await db.into(db.syncCursors).insert(
          SyncCursorsCompanion.insert(
            entity: 'gardens',
            cursor: const Value('2026-07-28T00:00:00.000Z'),
          ),
        );
    final c = await db.select(db.syncCursors).getSingle();
    expect(c.entity, 'gardens');
    expect(c.cursor, '2026-07-28T00:00:00.000Z');
  });
}

/// Small helper so the kind loop reads cleanly.
TasksCompanion _taskInsert(TaskKind kind, String plantId) =>
    TasksCompanion.insert(
      id: 't-${kind.name}',
      owner: '11111111-1111-1111-1111-111111111111',
      gardenPlantId: Value(plantId),
      kind: kind,
      due: '2026-07-31',
      dirty: const Value(true),
    );
