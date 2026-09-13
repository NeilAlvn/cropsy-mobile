// Sync engine against an in-memory transport: push clears dirty, pull applies
// remote rows and tombstones, dirty local rows survive a pull, cursor advances.

import 'package:cropsy/data/frost_presets.dart';
import 'package:cropsy/data/sample_week.dart';
import 'package:cropsy/data/seed.dart';
import 'package:cropsy/db/database.dart';
import 'package:cropsy/features/garden/garden_repository.dart';
import 'package:cropsy/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransport implements SyncTransport {
  final store = <String, Map<String, Map<String, dynamic>>>{};
  var _clock = DateTime.utc(2026, 5, 1);
  String _tick() => (_clock = _clock.add(const Duration(seconds: 1))).toIso8601String();

  /// Server-side write (another device).
  void remoteWrite(String table, Map<String, dynamic> row) {
    store.putIfAbsent(table, () => {})[row['id'] as String] = {...row, 'updated_at': _tick()};
  }

  @override
  Future<List<Map<String, dynamic>>> pull(String table, String owner, String? since, {int limit = 500}) async {
    final rows = (store[table] ?? {}).values.where((r) => r['owner'] == owner && (since == null || (r['updated_at'] as String).compareTo(since) > 0)).toList()
      ..sort((a, b) => (a['updated_at'] as String).compareTo(b['updated_at'] as String));
    return rows.take(limit).toList();
  }

  @override
  Future<void> push(String table, List<Map<String, dynamic>> rows) async {
    for (final r in rows) {
      remoteWrite(table, r);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('push, pull, tombstone, dirty-wins, cursor', () async {
    final repo = await GardenRepository.create(db: AppDatabase.memory(), today: demoToday, observations: (_, _) async => sampleObservations(demoToday));
    final transport = FakeTransport();
    final engine = SyncEngine(repo.db, transport);

    final gardenId = await repo.createGarden(region: defaultRegion, kind: GardenKind.balcony);
    final plantId = await repo.addPlant(gardenId: gardenId, cropSlug: 'lettuce', potLitres: 7, plantedOn: demoToday);
    await repo.saveProfile(preferences: {'experience': 'some'});

    var report = await engine.sync(repo.owner);
    expect(report.ok, isTrue, reason: '$report');
    expect(report.pushed['gardens'], 1);
    expect(report.pushed['garden_plants'], 1);
    expect(report.pushed['tasks'], greaterThan(0));
    expect(transport.store['profiles']![repo.owner]!['preferences'], {'experience': 'some'});
    // Push clears dirty; the pull-back of our own rows is a no-op.
    expect((await repo.db.select(repo.db.gardens).get()).single.dirty, isFalse);

    // Another device renames the garden and soft-deletes the plant.
    transport.remoteWrite('gardens', {...transport.store['gardens']![gardenId]!, 'name': 'Renamed'});
    transport.remoteWrite('garden_plants', {...transport.store['garden_plants']![plantId]!, 'deleted_at': '2026-05-02T00:00:00Z'});
    // Meanwhile a local, unsynced edit to the garden's sun hours.
    await repo.updateGarden(gardenId, sunHours: 3);

    report = await engine.sync(repo.owner);
    expect(report.ok, isTrue, reason: '$report');
    final garden = (await repo.gardens()).single;
    // Local dirty row was pushed (wins) — remote rename lost, sun hours kept.
    expect(garden.sunHours, 3);
    expect(transport.store['gardens']![gardenId]!['sun_hours'], 3);
    // Tombstone applied: the plant is gone from every query.
    expect(await repo.plants(), isEmpty);

    // Cursor advanced: a third sync pulls nothing.
    report = await engine.sync(repo.owner);
    expect(report.pulled.values.every((n) => n == 0), isTrue, reason: '$report');

    // Adopting an auth uid relabels rows and makes them dirty again.
    const uid = '22222222-2222-4222-8222-222222222222';
    await repo.adoptOwner(uid);
    expect((await repo.gardens()).single.owner, uid);
    expect((await repo.profile())!.id, uid);
    report = await engine.sync(uid);
    expect(report.pushed['gardens'], 1);

    repo.dispose();
  });

  test('a missing server table does not block the others', () async {
    final repo = await GardenRepository.create(db: AppDatabase.memory(), today: demoToday, observations: (_, _) async => sampleObservations(demoToday));
    final transport = _Failing(on: 'profiles');
    await repo.createGarden(region: defaultRegion, kind: GardenKind.garden);
    await repo.saveProfile(lang: 'en');
    final report = await SyncEngine(repo.db, transport).sync(repo.owner);
    expect(report.errors.keys, ['profiles']);
    expect(report.pushed['gardens'], 1, reason: '$report');
    // profiles stays dirty for next time.
    expect((await repo.profile())!.dirty, isTrue);
    repo.dispose();
  });
}

class _Failing extends FakeTransport {
  _Failing({required this.on});
  final String on;
  @override
  Future<void> push(String table, List<Map<String, dynamic>> rows) {
    if (table == on) throw StateError('relation "$table" does not exist');
    return super.push(table, rows);
  }
}
