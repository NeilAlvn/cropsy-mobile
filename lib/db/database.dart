/// Local database (Drift / SQLite) — the offline source of truth for user data.
///
/// Mirrors the Supabase schema `0001_syncable_foundation` (API contract §6) so
/// the same rows round-trip cleanly: `gardens`, `garden_plants`, `tasks`,
/// `journal_entries`. Every syncable row carries `id` (client-generatable uuid),
/// `owner`, `created_at`, `updated_at`, `deleted_at` (soft delete — we never
/// hard-delete a synced row, matching the server which grants no DELETE).
///
/// Two things here are LOCAL-ONLY and never sent to Supabase:
///   • `dirty` on each syncable table — set on a local write, cleared once the
///     row has been pushed. This is the outbox marker for optimistic sync.
///   • `SyncCursors` / `AppMeta` — the delta-pull high-water mark per table and
///     small key/value state (e.g. the bundled crop snapshot `version`).
///
/// Conflict policy is last-write-wins on `updated_at` — a single-user app, so no
/// CRDTs (agreed with backend). The actual push/pull engine is a later layer and
/// is gated on the Supabase auth handshake; this file is just the schema + DAO
/// surface it will build on.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../timing/weather_adjust.dart' show TaskKind, taskKindFromWire, taskKindToWire;

part 'database.g.dart';

/// F3 growing situation. Text-checked on the server; a typed enum locally.
enum GardenKind { balcony, garden, allotment }

const _gardenKindWire = <GardenKind, String>{
  GardenKind.balcony: 'balcony',
  GardenKind.garden: 'garden',
  GardenKind.allotment: 'allotment',
};

GardenKind _gardenKindFromWire(String s) => switch (s) {
      'balcony' => GardenKind.balcony,
      'garden' => GardenKind.garden,
      'allotment' => GardenKind.allotment,
      _ => throw ArgumentError('unknown garden kind: $s'),
    };

/// Stores [GardenKind] as its wire string so the local value is byte-identical
/// to what Supabase's CHECK constraint expects.
class GardenKindConverter extends TypeConverter<GardenKind, String> {
  const GardenKindConverter();
  @override
  GardenKind fromSql(String fromDb) => _gardenKindFromWire(fromDb);
  @override
  String toSql(GardenKind value) => _gardenKindWire[value]!;
}

/// Stores [TaskKind] as its snake_case wire string (`pot_on`, not `potOn`), so
/// it matches the server's frozen `tasks.kind` CHECK exactly.
class TaskKindConverter extends TypeConverter<TaskKind, String> {
  const TaskKindConverter();
  @override
  TaskKind fromSql(String fromDb) => taskKindFromWire(fromDb);
  @override
  String toSql(TaskKind value) => taskKindToWire(value);
}

/// Columns shared by every syncable table (API contract §6 guarantees).
mixin SyncableColumns on Table {
  /// Client-generatable uuid, so optimistic offline inserts work.
  TextColumn get id => text()();

  /// Owner uuid. Present locally for parity + push; a single user in practice.
  TextColumn get owner => text()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Soft delete — never hard-delete a synced row (the tombstone must sync).
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// LOCAL-ONLY: has unpushed local changes. Not a Supabase column.
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GardenRow')
class Gardens extends Table with SyncableColumns {
  TextColumn get name => text()();
  TextColumn get kind => text().map(const GardenKindConverter())();
  IntColumn get sunHours => integer().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();

  @override
  List<String> get customConstraints => [
        "CHECK (kind IN ('balcony', 'garden', 'allotment'))",
      ];
}

@DataClassName('GardenPlantRow')
class GardenPlants extends Table with SyncableColumns {
  /// FK to gardens.id. The server enforces a composite (id, owner) FK to block
  /// cross-owner references; locally there is one owner, so a plain FK suffices.
  TextColumn get gardenId =>
      text().references(Gardens, #id, onDelete: KeyAction.cascade)();

  /// Refers to the bundled crop reference data (crops-snapshot.json).
  TextColumn get cropSlug => text()();

  /// null = in-ground.
  IntColumn get potLitres => integer().nullable()();

  /// ISO `yyyy-mm-dd`, back-datable. Stored as text to match the engine + the
  /// Postgres `date` type without timezone drift.
  TextColumn get plantedOn => text().nullable()();
}

@DataClassName('TaskRow')
class Tasks extends Table with SyncableColumns {
  TextColumn get gardenPlantId =>
      text().nullable().references(GardenPlants, #id, onDelete: KeyAction.cascade)();

  /// Frozen enum, stored as the wire string. Mirrors the server CHECK.
  TextColumn get kind => text().map(const TaskKindConverter())();

  /// ISO `yyyy-mm-dd` the base schedule wants this done.
  TextColumn get due => text()();

  /// Back-datable completion (F4).
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  List<String> get customConstraints => [
        "CHECK (kind IN ('water', 'sow', 'transplant', 'harvest', 'feed', 'pot_on', 'thin'))",
      ];
}

@DataClassName('JournalEntryRow')
class JournalEntries extends Table with SyncableColumns {
  TextColumn get gardenPlantId =>
      text().nullable().references(GardenPlants, #id, onDelete: KeyAction.cascade)();

  /// ISO `yyyy-mm-dd`, back-datable (F5).
  TextColumn get entryOn => text()();
  TextColumn get note => text().nullable()();

  /// Storage key; the photo is compressed client-side before upload.
  TextColumn get photoPath => text().nullable()();
}

/// LOCAL-ONLY: the delta-pull cursor per table — the max `updated_at` seen, sent
/// as `changed_since` on the next pull.
@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  /// Which syncable table this cursor is for (e.g. `gardens`). Named `entity`
  /// rather than `tableName` — Drift reserves `tableName` for the SQL name.
  TextColumn get entity => text()();

  /// ISO-8601 UTC high-water mark; null = never pulled (full initial sync).
  TextColumn get cursor => text().nullable()();

  @override
  Set<Column> get primaryKey => {entity};
}

/// LOCAL-ONLY: small key/value state — e.g. `crop_snapshot_version`.
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Gardens, GardenPlants, Tasks, JournalEntries, SyncCursors, AppMeta],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          // FKs are off by default in SQLite; the composite/cascade relations
          // above only bite with this on.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static const cropSnapshotVersionKey = 'crop_snapshot_version';
}
