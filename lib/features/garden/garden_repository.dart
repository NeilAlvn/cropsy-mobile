/// GardenRepository — the single seam between the UI, the local Drift DB, and
/// the offline timing engine. The prototype runs on an in-memory DB seeded on
/// launch, so every demo run is clean and reproducible.
///
/// It exposes exactly what the screens need: the crop catalogue (F1), the user's
/// gardens/plants (F3), the "This Week" task list with weather hints (F2 + F4),
/// the per-plant journal (F5), and the harvest tracker (F7). Mutations bump a
/// [ChangeNotifier] so screens rebuild.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drift/drift.dart';

import '../../data/collections.dart';
import '../../data/crop_derived.dart';
import '../../data/frost_presets.dart';
import '../../data/sample_week.dart';
import '../../data/seed.dart';
import '../../db/database.dart';
import '../../timing/crop_snapshot.dart';
import '../../timing/dates.dart';
import '../../timing/engine.dart';
import '../../timing/types.dart';
import '../../timing/watering.dart';
import '../../timing/weather_adjust.dart';

/// A single row in the "This Week" list — a concrete, dated thing to do, with an
/// optional weather hint applied on top of the base schedule.
class ThisWeekItem {
  const ThisWeekItem({
    required this.taskId,
    required this.cropSlug,
    required this.cropName,
    required this.category,
    required this.kind,
    required this.due,
    required this.completed,
    this.hint,
  });

  final String taskId;
  final String cropSlug;
  final String cropName;
  final String category;
  final TaskKind kind;
  final String due;
  final bool completed;
  final Adjustment? hint;
}

class GardenRepository extends ChangeNotifier {
  GardenRepository._(this.db, this._snapshot, this.frost);

  final AppDatabase db;
  final CropSnapshot _snapshot;
  FrostProfile frost;
  String regionName = defaultRegion.name;

  final _rng = Random();
  String get today => demoToday;

  /// Open an in-memory DB, load the bundled crop snapshot, record its version.
  static Future<GardenRepository> create() async {
    final db = AppDatabase.memory();
    final raw = await rootBundle.loadString('assets/data/crops-snapshot.json');
    final snapshot = CropSnapshot.parse(raw);
    await db.into(db.appMeta).insert(
          AppMetaCompanion.insert(
            key: AppDatabase.cropSnapshotVersionKey,
            value: snapshot.version,
          ),
          mode: InsertMode.insertOrReplace,
        );
    return GardenRepository._(db, snapshot, defaultRegion.profile);
  }

  // ── Crop catalogue (F1) ────────────────────────────────────────────────
  List<Crop> get crops => _snapshot.crops;
  String get cropVersion => _snapshot.version;

  Crop? cropBySlug(String slug) {
    for (final c in _snapshot.crops) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  String cropName(String slug) => cropBySlug(slug)?.names.en ?? slug;
  String cropCategory(String slug) => cropBySlug(slug)?.category ?? 'herb';

  List<Collection>? _collections;
  List<Collection> get collections => _collections ??= buildCollections(crops);

  /// Crops with an activity window in [month] (1–12), optionally narrowed by a
  /// filter: 'indoors' (start indoors), 'outside' (sow/plant out), 'easy'.
  List<Crop> whatToGrowIn(int month, {String filter = 'all'}) {
    bool methodAllowed(MethodType m) => switch (filter) {
          'indoors' => m == MethodType.sowIndoor,
          'outside' => m == MethodType.sowDirect ||
              m == MethodType.transplant ||
              m == MethodType.plant,
          _ => true,
        };
    final out = <Crop>[];
    for (final crop in crops) {
      if (filter == 'easy' && difficultyOf(crop) != Difficulty.easy) continue;
      final hit = scheduleCrop(crop, frost).any((w) {
        if (!methodAllowed(w.method)) return false;
        final s = parseIso(w.start).month;
        final e = parseIso(w.end).month;
        return month >= s && month <= e;
      });
      if (hit) out.add(crop);
    }
    out.sort((a, b) => a.names.en.compareTo(b.names.en));
    return out;
  }

  // ── Gardens & plants (F3) ──────────────────────────────────────────────
  Future<List<GardenRow>> gardens() =>
      (db.select(db.gardens)..where((t) => t.deletedAt.isNull())).get();

  Future<bool> hasGarden() async => (await gardens()).isNotEmpty;

  Future<List<GardenPlantRow>> plants([String? gardenId]) {
    final q = db.select(db.gardenPlants)..where((t) => t.deletedAt.isNull());
    if (gardenId != null) q.where((t) => t.gardenId.equals(gardenId));
    return q.get();
  }

  Future<GardenPlantRow?> plantById(String id) =>
      (db.select(db.gardenPlants)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Lifecycle split (GrowIt's Planning vs Growing): a plant with no
  /// `plantedOn` is still being *planned*; once it's set, it's *growing*.
  Future<List<GardenPlantRow>> planningPlants() =>
      (db.select(db.gardenPlants)
            ..where((t) => t.deletedAt.isNull() & t.plantedOn.isNull()))
          .get();

  Future<List<GardenPlantRow>> growingPlants() =>
      (db.select(db.gardenPlants)
            ..where((t) => t.deletedAt.isNull() & t.plantedOn.isNotNull()))
          .get();

  /// Rough days-until-harvest for a growing plant (GrowIt's "Harvest in N days"
  /// countdown): planted date + the crop's min harvest days − today.
  int? daysUntilHarvest(GardenPlantRow plant) {
    if (plant.plantedOn == null) return null;
    final crop = cropBySlug(plant.cropSlug);
    if (crop == null) return null;
    final harvest = addDays(parseIso(plant.plantedOn!), crop.harvestDaysMin.toInt());
    return harvest.difference(parseIso(today)).inDays;
  }

  /// Move a planned plant into "growing" by stamping today's date.
  Future<void> startGrowing(String plantId) async {
    await (db.update(db.gardenPlants)..where((t) => t.id.equals(plantId))).write(
      GardenPlantsCompanion(
        plantedOn: Value(today),
        dirty: const Value(true),
      ),
    );
    notifyListeners();
  }

  /// Move a growing plant back to "planning" (undo an accidental Start).
  Future<void> stopGrowing(String plantId) async {
    await (db.update(db.gardenPlants)..where((t) => t.id.equals(plantId))).write(
      const GardenPlantsCompanion(
        plantedOn: Value(null),
        dirty: Value(true),
      ),
    );
    notifyListeners();
  }

  /// Remove a plant the user added by mistake. Soft delete (sets deletedAt) —
  /// the tombstone syncs, and every plant query already filters it out, so its
  /// tasks/journal drop with it. Logged harvests stay in the season history.
  Future<void> removePlant(String plantId) async {
    await (db.update(db.gardenPlants)..where((t) => t.id.equals(plantId))).write(
      GardenPlantsCompanion(
        deletedAt: Value(DateTime.now()),
        dirty: const Value(true),
      ),
    );
    notifyListeners();
  }

  /// Edit a plant's pot size or planted date (fix a mistake after adding).
  Future<void> updatePlant(
    String plantId, {
    int? potLitres,
    String? plantedOn,
  }) async {
    await (db.update(db.gardenPlants)..where((t) => t.id.equals(plantId))).write(
      GardenPlantsCompanion(
        potLitres: Value(potLitres),
        plantedOn: Value(plantedOn),
        dirty: const Value(true),
      ),
    );
    notifyListeners();
  }

  /// Personalize the garden itself: rename it, change the growing situation, or
  /// adjust sun hours after onboarding.
  Future<void> updateGarden(
    String gardenId, {
    String? name,
    GardenKind? kind,
    int? sunHours,
  }) async {
    await (db.update(db.gardens)..where((t) => t.id.equals(gardenId))).write(
      GardensCompanion(
        name: name == null ? const Value.absent() : Value(name),
        kind: kind == null ? const Value.absent() : Value(kind),
        sunHours: sunHours == null ? const Value.absent() : Value(sunHours),
        dirty: const Value(true),
      ),
    );
    notifyListeners();
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_rng.nextInt(1 << 20).toRadixString(36)}';

  /// Change the growing location after setup (from the Home header / settings).
  /// Re-points the frost profile — which every planting date, "what to grow this
  /// month", and reminder is computed from — and persists the coordinate on the
  /// current garden so it round-trips like the real (frost-API-backed) value.
  Future<void> setRegion(FrostRegion region) async {
    frost = region.profile;
    regionName = region.name;
    final existing = await gardens();
    if (existing.isNotEmpty) {
      await (db.update(db.gardens)..where((t) => t.id.equals(existing.first.id)))
          .write(GardensCompanion(
        lat: Value(region.lat),
        lon: Value(region.lon),
        dirty: const Value(true),
      ));
    }
    notifyListeners();
  }

  Future<String> createGarden({
    required FrostRegion region,
    required GardenKind kind,
    int? sunHours,
    String name = 'My garden',
  }) async {
    frost = region.profile;
    regionName = region.name;
    final id = _newId();
    await db.into(db.gardens).insert(GardensCompanion.insert(
          id: id,
          owner: demoOwner,
          name: name,
          kind: kind,
          sunHours: Value(sunHours),
          lat: Value(region.lat),
          lon: Value(region.lon),
          dirty: const Value(true),
        ));
    notifyListeners();
    return id;
  }

  Future<void> addPlant({
    required String gardenId,
    required String cropSlug,
    int? potLitres,
    String? plantedOn,
  }) async {
    await db.into(db.gardenPlants).insert(GardenPlantsCompanion.insert(
          id: _newId(),
          owner: demoOwner,
          gardenId: gardenId,
          cropSlug: cropSlug,
          potLitres: Value(potLitres),
          plantedOn: Value(plantedOn),
          dirty: const Value(true),
        ));
    notifyListeners();
  }

  /// "Skip" shortcut: a Randstad balcony pre-stocked with the starter crops.
  Future<void> seedDemoGarden() async {
    final gardenId = await createGarden(
      region: defaultRegion,
      kind: GardenKind.balcony,
      sunHours: 6,
      name: 'Balcony',
    );
    // A couple stay in "planning" (no plantedOn) so both My Garden sub-tabs
    // have content; the rest are actively growing (drive tasks/reminders).
    const planningOnly = {'carrot', 'courgette'};
    for (final entry in starterCrops.entries) {
      await addPlant(
        gardenId: gardenId,
        cropSlug: entry.key,
        potLitres: entry.value,
        plantedOn: planningOnly.contains(entry.key) ? null : today,
      );
    }
  }

  // ── This Week (F2) + weather hints (F4) ────────────────────────────────
  TaskKind _kindForMethod(MethodType m) => switch (m) {
        MethodType.sowIndoor => TaskKind.sow,
        MethodType.sowDirect => TaskKind.sow,
        MethodType.transplant => TaskKind.transplant,
        MethodType.plant => TaskKind.transplant,
      };

  /// Regenerate the concrete tasks for `[today, today+7)` from the base schedule
  /// + client-side watering, upserting into the real `tasks` table. Stable ids +
  /// insert-or-ignore preserve any completion the user already made.
  Future<void> _regenerateTasks() async {
    final active = await growingPlants();
    for (final plant in active) {
      final crop = cropBySlug(plant.cropSlug);
      if (crop == null) continue;

      // Base schedule windows overlapping this week → sow / plant-out tasks.
      final windows = windowsActiveInRange(scheduleCrop(crop, frost), today);
      for (final w in windows) {
        final due = w.start.compareTo(today) < 0 ? today : w.start;
        await db.into(db.tasks).insert(
              TasksCompanion.insert(
                id: 'base-${plant.id}-${w.method.name}-${w.start}',
                owner: demoOwner,
                gardenPlantId: Value(plant.id),
                kind: _kindForMethod(w.method),
                due: due,
                dirty: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      // Client-owned watering cadence.
      for (final wt in wateringTasksFor(
        plantId: plant.id,
        cropSlug: plant.cropSlug,
        potLitres: plant.potLitres,
        today: today,
      )) {
        await db.into(db.tasks).insert(
              TasksCompanion.insert(
                id: wt.id,
                owner: demoOwner,
                gardenPlantId: Value(plant.id),
                kind: TaskKind.water,
                due: wt.due,
                dirty: const Value(true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    }
  }

  /// The soil-temp gate for a sow/transplant task, pulled from the crop method,
  /// so the weather layer can defer it. null for waterings.
  num? _soilGate(String cropSlug, TaskKind kind) {
    final crop = cropBySlug(cropSlug);
    if (crop == null) return null;
    for (final m in crop.methods) {
      if (_kindForMethod(m.type) == kind && m.minSoilC != null) {
        return m.minSoilC;
      }
    }
    return null;
  }

  Future<List<ThisWeekItem>> thisWeek() async {
    await _regenerateTasks();
    final end = toIso(addDays(parseIso(today), 7));
    final rows = await (db.select(db.tasks)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.due.isBiggerOrEqualValue(today) &
              t.due.isSmallerThanValue(end)))
        .get();

    // Weather hints (F4): run the real adjuster over a prototype sample forecast.
    final plantById = {for (final p in await plants()) p.id: p};
    final timingTasks = <Task>[
      for (final r in rows)
        Task(
          id: r.id,
          cropSlug: plantById[r.gardenPlantId]?.cropSlug ?? '',
          kind: r.kind,
          due: r.due,
          minSoilC: _soilGate(
            plantById[r.gardenPlantId]?.cropSlug ?? '',
            r.kind,
          ),
        ),
    ];
    final hints = {
      for (final a in adjustTasks(timingTasks, sampleObservations(today)))
        a.taskId: a,
    };

    final items = <ThisWeekItem>[
      for (final r in rows)
        if (plantById[r.gardenPlantId] != null)
          ThisWeekItem(
            taskId: r.id,
            cropSlug: plantById[r.gardenPlantId]!.cropSlug,
            cropName: cropName(plantById[r.gardenPlantId]!.cropSlug),
            category: cropCategory(plantById[r.gardenPlantId]!.cropSlug),
            kind: r.kind,
            due: r.due,
            completed: r.completedAt != null,
            hint: hints[r.id],
          ),
    ];
    items.sort((a, b) {
      final c = a.due.compareTo(b.due);
      return c != 0 ? c : a.kind.index.compareTo(b.kind.index);
    });
    return items;
  }

  Future<void> setTaskCompleted(String taskId, bool completed) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        completedAt: Value(completed ? DateTime.now() : null),
        dirty: const Value(true),
      ),
    );
    notifyListeners();
  }

  // ── Journal (F5) ───────────────────────────────────────────────────────
  Future<List<JournalEntryRow>> journal(String plantId) =>
      (db.select(db.journalEntries)
            ..where((t) => t.gardenPlantId.equals(plantId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.entryOn)]))
          .get();

  Future<void> addJournalEntry({
    required String plantId,
    required String note,
    String? photoPath,
    String? entryOn,
  }) async {
    await db.into(db.journalEntries).insert(JournalEntriesCompanion.insert(
          id: _newId(),
          owner: demoOwner,
          gardenPlantId: Value(plantId),
          entryOn: entryOn ?? today,
          note: Value(note),
          photoPath: Value(photoPath),
          dirty: const Value(true),
        ));
    notifyListeners();
  }

  // ── Harvest (F7) ───────────────────────────────────────────────────────
  Future<List<HarvestRow>> harvests() => (db.select(db.harvests)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.harvestedOn)]))
      .get();

  Future<double> seasonHarvestValue() async {
    final rows = await harvests();
    return rows.fold<double>(0, (sum, r) => sum + r.valueEuros);
  }

  Future<void> logHarvest({
    required String cropSlug,
    String? plantId,
    required String amount,
    required double valueEuros,
    String? harvestedOn,
  }) async {
    await db.into(db.harvests).insert(HarvestsCompanion.insert(
          id: _newId(),
          owner: demoOwner,
          gardenPlantId: Value(plantId),
          cropSlug: cropSlug,
          amount: amount,
          valueEuros: Value(valueEuros),
          harvestedOn: harvestedOn ?? today,
          dirty: const Value(true),
        ));
    notifyListeners();
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }
}
