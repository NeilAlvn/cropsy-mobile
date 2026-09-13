/// Row ⇄ wire mapping for the syncable tables (API-CONTRACT §6, migration
/// 0002). Explicit per table so the JSON is exactly what Supabase expects:
/// snake_case, ISO dates, jsonb as objects. `updated_at`/`created_at` are
/// server-maintained and never pushed; `dirty` and `start_method` are local.
///
/// Pulled rows are applied with UPSERT (on conflict do update), never
/// INSERT OR REPLACE: with foreign keys on, REPLACE deletes the old row first
/// and cascades that delete into every child table.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';

String? _ts(DateTime? d) => d?.toUtc().toIso8601String();
DateTime? _dt(Object? v) => v == null ? null : DateTime.parse(v as String).toUtc();

/// Everything one table needs to sync.
class TableSync<R> {
  const TableSync({
    required this.name,
    required this.selectDirty,
    required this.toWire,
    required this.upsertFromWire,
    required this.markClean,
    required this.localById,
  });

  final String name;
  final Future<List<R>> Function(AppDatabase db, String owner) selectDirty;
  final Map<String, dynamic> Function(R row) toWire;
  final Future<void> Function(AppDatabase db, Map<String, dynamic> wire) upsertFromWire;
  final Future<void> Function(AppDatabase db, Iterable<String> ids) markClean;
  final Future<({bool exists, bool dirty})> Function(AppDatabase db, String id) localById;

  /// Dirty rows as wire maps, typed here so callers can hold a
  /// `TableSync<dynamic>` without tripping function-type variance.
  Future<List<Map<String, dynamic>>> dirtyWires(AppDatabase db, String owner) async =>
      [for (final r in await selectDirty(db, owner)) toWire(r)];
}

Future<void> _clean(AppDatabase db, TableInfo<Table, dynamic> t, Iterable<String> ids) async {
  for (final id in ids) {
    await db.customUpdate(
      'UPDATE ${t.actualTableName} SET dirty = 0 WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {t},
    );
  }
}

Future<({bool exists, bool dirty})> _probe(AppDatabase db, TableInfo<Table, dynamic> t, String id) async {
  final rows = await db.customSelect(
    'SELECT dirty FROM ${t.actualTableName} WHERE id = ?',
    variables: [Variable.withString(id)],
  ).get();
  if (rows.isEmpty) return (exists: false, dirty: false);
  return (exists: true, dirty: rows.first.read<bool>('dirty'));
}

final profilesSync = TableSync<ProfileRow>(
  name: 'profiles',
  selectDirty: (db, owner) =>
      (db.select(db.profiles)..where((t) => t.dirty.equals(true) & t.owner.equals(owner))).get(),
  toWire: (r) => {
    'id': r.id,
    'owner': r.owner,
    'display_name': r.displayName,
    'lang': r.lang,
    'preferences': jsonDecode(r.preferences),
    'streak_count': r.streakCount,
    'streak_frozen_until': r.streakFrozenUntil,
    'deleted_at': _ts(r.deletedAt),
  },
  upsertFromWire: (db, w) => db.into(db.profiles).insertOnConflictUpdate(
        ProfilesCompanion(
          id: Value(w['id'] as String),
          owner: Value(w['owner'] as String),
          displayName: Value(w['display_name'] as String?),
          lang: Value(w['lang'] as String? ?? 'nl'),
          preferences: Value(jsonEncode(w['preferences'] ?? {})),
          streakCount: Value((w['streak_count'] as num?)?.toInt() ?? 0),
          streakFrozenUntil: Value(w['streak_frozen_until'] as String?),
          createdAt: Value(_dt(w['created_at']) ?? DateTime.now()),
          updatedAt: Value(_dt(w['updated_at']) ?? DateTime.now()),
          deletedAt: Value(_dt(w['deleted_at'])),
          dirty: const Value(false),
        ),
      ),
  markClean: (db, ids) => _clean(db, db.profiles, ids),
  localById: (db, id) => _probe(db, db.profiles, id),
);

final gardensSync = TableSync<GardenRow>(
  name: 'gardens',
  selectDirty: (db, owner) =>
      (db.select(db.gardens)..where((t) => t.dirty.equals(true) & t.owner.equals(owner))).get(),
  toWire: (r) => {
    'id': r.id,
    'owner': r.owner,
    'name': r.name,
    'kind': const GardenKindConverter().toSql(r.kind),
    'sun_hours': r.sunHours,
    'lat': r.lat,
    'lon': r.lon,
    'size_m2': r.sizeM2,
    'layout': r.layout == null ? null : jsonDecode(r.layout!),
    'postcode': r.postcode,
    'deleted_at': _ts(r.deletedAt),
  },
  upsertFromWire: (db, w) => db.into(db.gardens).insertOnConflictUpdate(
        GardensCompanion(
          id: Value(w['id'] as String),
          owner: Value(w['owner'] as String),
          name: Value(w['name'] as String),
          kind: Value(const GardenKindConverter().fromSql(w['kind'] as String)),
          sunHours: Value((w['sun_hours'] as num?)?.toInt()),
          lat: Value((w['lat'] as num?)?.toDouble()),
          lon: Value((w['lon'] as num?)?.toDouble()),
          sizeM2: Value((w['size_m2'] as num?)?.toInt()),
          layout: Value(w['layout'] == null ? null : jsonEncode(w['layout'])),
          postcode: Value(w['postcode'] as String?),
          createdAt: Value(_dt(w['created_at']) ?? DateTime.now()),
          updatedAt: Value(_dt(w['updated_at']) ?? DateTime.now()),
          deletedAt: Value(_dt(w['deleted_at'])),
          dirty: const Value(false),
        ),
      ),
  markClean: (db, ids) => _clean(db, db.gardens, ids),
  localById: (db, id) => _probe(db, db.gardens, id),
);

final gardenPlantsSync = TableSync<GardenPlantRow>(
  name: 'garden_plants',
  selectDirty: (db, owner) =>
      (db.select(db.gardenPlants)..where((t) => t.dirty.equals(true) & t.owner.equals(owner))).get(),
  toWire: (r) => {
    'id': r.id,
    'owner': r.owner,
    'garden_id': r.gardenId,
    'crop_slug': r.cropSlug,
    'pot_litres': r.potLitres,
    'planted_on': r.plantedOn,
    'variety_slug': r.varietySlug,
    'stage': r.stage,
    'stage_changed_on': r.stageChangedOn,
    'place': r.place,
    'deleted_at': _ts(r.deletedAt),
  },
  upsertFromWire: (db, w) => db.into(db.gardenPlants).insertOnConflictUpdate(
        GardenPlantsCompanion(
          id: Value(w['id'] as String),
          owner: Value(w['owner'] as String),
          gardenId: Value(w['garden_id'] as String),
          cropSlug: Value(w['crop_slug'] as String),
          potLitres: Value((w['pot_litres'] as num?)?.toInt()),
          plantedOn: Value(w['planted_on'] as String?),
          varietySlug: Value(w['variety_slug'] as String?),
          stage: Value(w['stage'] as String?),
          stageChangedOn: Value(w['stage_changed_on'] as String?),
          place: Value(w['place'] as String?),
          createdAt: Value(_dt(w['created_at']) ?? DateTime.now()),
          updatedAt: Value(_dt(w['updated_at']) ?? DateTime.now()),
          deletedAt: Value(_dt(w['deleted_at'])),
          dirty: const Value(false),
        ),
      ),
  markClean: (db, ids) => _clean(db, db.gardenPlants, ids),
  localById: (db, id) => _probe(db, db.gardenPlants, id),
);

final tasksSync = TableSync<TaskRow>(
  name: 'tasks',
  selectDirty: (db, owner) =>
      (db.select(db.tasks)..where((t) => t.dirty.equals(true) & t.owner.equals(owner))).get(),
  toWire: (r) => {
    'id': r.id,
    'owner': r.owner,
    'garden_plant_id': r.gardenPlantId,
    'kind': const TaskKindConverter().toSql(r.kind),
    'due': r.due,
    'completed_at': _ts(r.completedAt),
    'node_kind': r.nodeKind,
    'planned_due': r.plannedDue,
    'moved_reason': r.movedReason,
    'skipped': r.skipped,
    'deleted_at': _ts(r.deletedAt),
  },
  upsertFromWire: (db, w) => db.into(db.tasks).insertOnConflictUpdate(
        TasksCompanion(
          id: Value(w['id'] as String),
          owner: Value(w['owner'] as String),
          gardenPlantId: Value(w['garden_plant_id'] as String?),
          kind: Value(const TaskKindConverter().fromSql(w['kind'] as String)),
          due: Value(w['due'] as String),
          completedAt: Value(_dt(w['completed_at'])),
          nodeKind: Value(w['node_kind'] as String?),
          plannedDue: Value(w['planned_due'] as String?),
          movedReason: Value(w['moved_reason'] as String?),
          skipped: Value(w['skipped'] as bool? ?? false),
          createdAt: Value(_dt(w['created_at']) ?? DateTime.now()),
          updatedAt: Value(_dt(w['updated_at']) ?? DateTime.now()),
          deletedAt: Value(_dt(w['deleted_at'])),
          dirty: const Value(false),
        ),
      ),
  markClean: (db, ids) => _clean(db, db.tasks, ids),
  localById: (db, id) => _probe(db, db.tasks, id),
);

final journalSync = TableSync<JournalEntryRow>(
  name: 'journal_entries',
  selectDirty: (db, owner) =>
      (db.select(db.journalEntries)..where((t) => t.dirty.equals(true) & t.owner.equals(owner))).get(),
  toWire: (r) => {
    'id': r.id,
    'owner': r.owner,
    'garden_plant_id': r.gardenPlantId,
    'entry_on': r.entryOn,
    'note': r.note,
    'photo_path': r.photoPath,
    'mood': r.mood,
    'stage': r.stage,
    'photo_paths': jsonDecode(r.photoPaths),
    'deleted_at': _ts(r.deletedAt),
  },
  upsertFromWire: (db, w) => db.into(db.journalEntries).insertOnConflictUpdate(
        JournalEntriesCompanion(
          id: Value(w['id'] as String),
          owner: Value(w['owner'] as String),
          gardenPlantId: Value(w['garden_plant_id'] as String?),
          entryOn: Value(w['entry_on'] as String),
          note: Value(w['note'] as String?),
          photoPath: Value(w['photo_path'] as String?),
          mood: Value((w['mood'] as num?)?.toInt()),
          stage: Value(w['stage'] as String?),
          photoPaths: Value(jsonEncode(w['photo_paths'] ?? const [])),
          createdAt: Value(_dt(w['created_at']) ?? DateTime.now()),
          updatedAt: Value(_dt(w['updated_at']) ?? DateTime.now()),
          deletedAt: Value(_dt(w['deleted_at'])),
          dirty: const Value(false),
        ),
      ),
  markClean: (db, ids) => _clean(db, db.journalEntries, ids),
  localById: (db, id) => _probe(db, db.journalEntries, id),
);

/// Parent-before-child order, so pulled FKs resolve.
final syncTables = <TableSync<dynamic>>[
  profilesSync,
  gardensSync,
  gardenPlantsSync,
  tasksSync,
  journalSync,
];
