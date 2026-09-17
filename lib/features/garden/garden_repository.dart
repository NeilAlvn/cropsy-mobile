/// GardenRepository — the single seam between the UI, the local Drift DB, and
/// the offline timing engines (base schedule, watering, timeline replan).
///
/// It exposes exactly what the screens need: the crop catalogue, the user's
/// gardens/plants, the per-plant timeline path (PRD §7), the "This Week" list
/// with weather hints, the journal, and the harvest tracker. Mutations bump a
/// [ChangeNotifier] so screens rebuild.
///
/// `today` is injectable (tests pin a spring date); production reads the clock.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drift/drift.dart';
import '../../timing/replan.dart' as engine show logNode;

import '../../data/collections.dart';
import '../../data/crop_derived.dart';
import '../../data/frost_presets.dart';
import '../../data/seed.dart';
import '../../db/database.dart';
import '../../db/uuid.dart';
import '../../timing/content_snapshot.dart';
import '../../timing/crop_snapshot.dart';
import '../../timing/dates.dart';
import '../../timing/engine.dart';
import '../../timing/replan.dart';
import '../../timing/season.dart';
import '../../timing/types.dart';
import '../../timing/watering.dart';
import '../../timing/streak.dart';
import '../../timing/weather_adjust.dart';
import 'weather_service.dart';

/// A single row in the "This Week" list — a concrete, dated thing to do, with an
/// optional weather hint applied on top of the base schedule.
class ThisWeekItem {
  const ThisWeekItem({
    required this.taskId,
    this.plantId,
    required this.cropSlug,
    required this.cropNames,
    required this.category,
    required this.kind,
    required this.due,
    required this.completed,
    this.hint,
  });

  final String taskId;
  final String? plantId;
  final String cropSlug;

  /// The crop's name in both languages, so a screen and a notification can
  /// each pick their own side.
  final LocalizedText cropNames;
  final String category;
  final TaskKind kind;
  final String due;
  final bool completed;
  final Adjustment? hint;
}

class GardenRepository extends ChangeNotifier {
  GardenRepository._(this.db, this._snapshot, this.frost, this.owner, this._fixedToday, this._observations);

  /// Collections, monthly checklist, prices (PRD §8.1). Near-empty until the
  /// Phase 3 content sprint; the shape is fixed.
  ContentSnapshot content = ContentSnapshot.empty;

  /// Where the weather overlay gets its observations. Production: live
  /// Open-Meteo via [WeatherService]; tests inject a scripted series.
  final Future<List<DayObservation>?> Function(double lat, double lon) _observations;

  /// Last observations used by [thisWeek], for the weather banner.
  List<DayObservation>? lastObservations;

  final AppDatabase db;
  final CropSnapshot _snapshot;
  FrostProfile frost;
  String regionName = defaultRegion.name;

  /// Owner uuid on every row: anonymous until sign-in (PRD Phase 1 auth).
  String owner;

  /// Sign-in: re-label every local row with the auth uid so it syncs under
  /// RLS, and remember the uid as the owner from now on.
  Future<void> adoptOwner(String uid) async {
    final old = owner;
    await db.transaction(() async {
      for (final t in ['gardens', 'garden_plants', 'tasks', 'journal_entries', 'harvests', 'feedback']) {
        await db.customUpdate(
          'UPDATE $t SET owner = ?, dirty = 1 WHERE owner = ?',
          variables: [Variable.withString(uid), Variable.withString(old)],
          updateKind: UpdateKind.update,
        );
      }
      // profiles.id must equal the uid on the server: re-key the anonymous row.
      await db.customUpdate(
        'UPDATE profiles SET id = ?, owner = ?, dirty = 1 WHERE owner = ?',
        variables: [Variable.withString(uid), Variable.withString(uid), Variable.withString(old)],
        updateKind: UpdateKind.update,
      );
      await db.into(db.appMeta).insert(
            AppMetaCompanion.insert(key: AppDatabase.ownerKey, value: uid),
            mode: InsertMode.insertOrReplace,
          );
    });
    owner = uid;
    notifyListeners();
  }

  // ── Small local key/value state (AppMeta) ───────────────────────────────
  Future<String?> meta(String key) async =>
      (await (db.select(db.appMeta)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setMeta(String key, String value) =>
      db.into(db.appMeta).insert(AppMetaCompanion.insert(key: key, value: value), mode: InsertMode.insertOrReplace);

  // ── Profile (PRD 1.6 answers, streaks) ──────────────────────────────────
  Future<ProfileRow?> profile() =>
      (db.select(db.profiles)..where((t) => t.id.equals(owner))).getSingleOrNull();

  Future<void> saveProfile({Map<String, dynamic>? preferences, String? lang, String? displayName}) async {
    final existing = await profile();
    final merged = {...?(existing == null ? null : jsonDecode(existing.preferences) as Map<String, dynamic>), ...?preferences};
    await db.into(db.profiles).insert(
          ProfilesCompanion(
            id: Value(owner),
            owner: Value(owner),
            displayName: Value(displayName ?? existing?.displayName),
            lang: Value(lang ?? existing?.lang ?? 'nl'),
            preferences: Value(jsonEncode(merged)),
            streakCount: Value(existing?.streakCount ?? 0),
            streakFrozenUntil: Value(existing?.streakFrozenUntil),
            dirty: const Value(true),
          ),
          mode: InsertMode.insertOrReplace,
        );
    notifyListeners();
  }

  final String? _fixedToday;
  String get today => _fixedToday ?? _localToday();
  int get _year => parseIso(today).year;

  static String _localToday() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  /// Load the bundled crop snapshot, record its version, resolve the owner id.
  /// [today] pins the clock (tests); null = real calendar.
  static Future<GardenRepository> create({
    required AppDatabase db,
    String? today,
    Future<List<DayObservation>?> Function(double lat, double lon)? observations,
  }) async {
    final raw = await rootBundle.loadString('assets/data/crops-snapshot.json');
    final snapshot = CropSnapshot.parse(raw);
    ContentSnapshot content;
    try {
      content = ContentSnapshot.parse(await rootBundle.loadString('assets/data/content-snapshot.json'));
    } catch (_) {
      content = ContentSnapshot.empty;
    }
    await db.into(db.appMeta).insert(
          AppMetaCompanion.insert(
            key: AppDatabase.cropSnapshotVersionKey,
            value: snapshot.version,
          ),
          mode: InsertMode.insertOrReplace,
        );
    final ownerRow = await (db.select(db.appMeta)
          ..where((t) => t.key.equals(AppDatabase.ownerKey)))
        .getSingleOrNull();
    var owner = ownerRow?.value;
    if (owner == null) {
      owner = newUuid();
      await db.into(db.appMeta).insert(
          AppMetaCompanion.insert(key: AppDatabase.ownerKey, value: owner));
    }
    final repo = GardenRepository._(
      db, snapshot, defaultRegion.profile, owner, today,
      observations ?? WeatherService(db).observations,
    )..content = content;
    repo.frost = defaultRegion.profile.withYear(repo._year);
    return repo;
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

  /// The crop's name in both languages. Everything the gardener reads goes
  /// through this and picks a side with `.of(context)`.
  LocalizedText cropNames(String slug) =>
      cropBySlug(slug)?.names ?? LocalizedText(nl: slug, en: slug);

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

  /// Days until the timeline's harvest node (GrowIt's "Harvest in N days").
  /// null while planning or when no path exists yet.
  Future<int?> daysUntilHarvest(GardenPlantRow plant) async {
    if (plant.plantedOn == null) return null;
    final path = await pathFor(plant.id);
    for (final n in path) {
      if (n.kind == NodeKind.harvest) {
        return parseIso(n.due).difference(parseIso(today)).inDays;
      }
    }
    return null;
  }

  /// Planner grid layout (PRD 5.1), JSON `{cols, rows, cells}` on the garden.
  Future<void> saveLayout(String gardenId, Map<String, dynamic> layout) async {
    await (db.update(db.gardens)..where((t) => t.id.equals(gardenId))).write(
      GardensCompanion(layout: Value(jsonEncode(layout)), dirty: const Value(true)),
    );
    notifyListeners();
  }

  /// Season path (PRD 7.4) for every plant in the garden, planning included.
  Future<List<SeasonNode>> seasonNodes() async {
    final all = await plants();
    final sp = <SeasonPlant>[];
    for (final p in all) {
      PathNode? harvest;
      if (p.plantedOn != null) {
        for (final n in await pathFor(p.id)) {
          if (n.kind == NodeKind.harvest && n.loggedOn == null) {
            harvest = n;
            break;
          }
        }
      }
      sp.add(SeasonPlant(plantId: p.id, cropSlug: p.cropSlug, harvestStart: harvest?.due, harvestEnd: harvest?.until ?? harvest?.due));
    }
    return seasonPath(sp, crops, frost);
  }

  /// Planning 5.2: months (1–12) with an outdoor sow/plant window for a crop.
  List<int> plantMonths(Crop crop) {
    final months = <int>{};
    for (final w in scheduleCrop(crop, frost)) {
      if (w.method == MethodType.sowIndoor) continue;
      var d = parseIso(w.start);
      final end = parseIso(w.end);
      while (!d.isAfter(end)) {
        months.add(d.month);
        d = DateTime.utc(d.year, d.month + 1, 1);
      }
    }
    return months.toList()..sort();
  }

  /// Every plant's pending path nodes, for the season path: the steps between
  /// sowing and harvest that the crop schedule alone does not know about.
  ///
  /// Watering is left out on purpose. It recurs, the weather overlay already
  /// moves it, and a path with a watering node every few days is a list, not a
  /// path (PRD §7.1 collapses it).
  Future<List<({String plantId, String cropSlug, PathNode node})>> seasonTasks() async {
    const wanted = {NodeKind.potOn, NodeKind.transplant, NodeKind.thin, NodeKind.feed};
    final out = <({String plantId, String cropSlug, PathNode node})>[];
    for (final plant in await growingPlants()) {
      for (final node in await pathFor(plant.id)) {
        if (!wanted.contains(node.kind)) continue;
        if (node.loggedOn != null || node.skipped) continue;
        out.add((plantId: plant.id, cropSlug: plant.cropSlug, node: node));
      }
    }
    out.sort((a, b) => a.node.due.compareTo(b.node.due));
    return out;
  }

  /// Home 2.4: growing plants with their harvest window, soonest first.
  Future<List<({GardenPlantRow plant, PathNode harvest})>> upcomingHarvests() async {
    final out = <({GardenPlantRow plant, PathNode harvest})>[];
    for (final p in await growingPlants()) {
      for (final n in await pathFor(p.id)) {
        if (n.kind == NodeKind.harvest && n.loggedOn == null) {
          out.add((plant: p, harvest: n));
          break;
        }
      }
    }
    out.sort((a, b) => a.harvest.due.compareTo(b.harvest.due));
    return out;
  }

  /// The method a plant's path starts from when the user just says "planted":
  /// outdoor starts first (a bought tomato seedling is a transplant), indoor
  /// sowing only when that is the crop's sole method.
  MethodType defaultStartMethod(Crop crop) {
    const order = [MethodType.transplant, MethodType.sowDirect, MethodType.plant, MethodType.sowIndoor];
    for (final t in order) {
      if (crop.methods.any((m) => m.type == t)) return t;
    }
    return MethodType.sowDirect;
  }

  /// Move a planned plant into "growing": stamp the date, build its path.
  Future<void> startGrowing(String plantId, {MethodType? method, String? on}) async {
    final plant = await plantById(plantId);
    if (plant == null) return;
    final crop = cropBySlug(plant.cropSlug);
    final m = method ?? (crop == null ? MethodType.sowDirect : defaultStartMethod(crop));
    final date = on ?? today;
    await (db.update(db.gardenPlants)..where((t) => t.id.equals(plantId))).write(
      GardenPlantsCompanion(
        plantedOn: Value(date),
        stage: const Value('starting'),
        stageChangedOn: Value(date),
        startMethod: Value(methodToWire(m)),
        dirty: const Value(true),
      ),
    );
    if (crop != null) await _rebuildPath(plantId, crop, m, date);
    notifyListeners();
  }

  /// Move a growing plant back to "planning" (undo an accidental Start).
  Future<void> stopGrowing(String plantId) async {
    await (db.update(db.gardenPlants)..where((t) => t.id.equals(plantId))).write(
      const GardenPlantsCompanion(
        plantedOn: Value(null),
        stage: Value(null),
        stageChangedOn: Value(null),
        dirty: Value(true),
      ),
    );
    await _clearPath(plantId);
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
  /// A changed planting date rebuilds the path from the same start method.
  Future<void> updatePlant(
    String plantId, {
    int? potLitres,
    String? plantedOn,
  }) async {
    final before = await plantById(plantId);
    await (db.update(db.gardenPlants)..where((t) => t.id.equals(plantId))).write(
      GardenPlantsCompanion(
        potLitres: Value(potLitres),
        plantedOn: Value(plantedOn),
        dirty: const Value(true),
      ),
    );
    if (before != null && plantedOn != null && plantedOn != before.plantedOn) {
      final crop = cropBySlug(before.cropSlug);
      if (crop != null) {
        final m = before.startMethod != null
            ? methodFromWire(before.startMethod!)
            : defaultStartMethod(crop);
        // ponytail: rebuild drops logged nodes; keep them if users edit dates after logging.
        await _rebuildPath(plantId, crop, m, plantedOn);
      }
    }
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

  /// Change the growing location after setup (from the Home header / settings).
  /// Re-points the frost profile — which every planting date, "what to grow this
  /// month", and reminder is computed from — and persists the coordinate on the
  /// current garden so it round-trips like the real (frost-API-backed) value.
  Future<void> setRegion(FrostRegion region) async {
    frost = region.profile.withYear(_year);
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

  /// A resolved location (GPS / postcode → frost API) rather than a preset.
  Future<void> setLocation({
    required String name,
    required FrostProfile profile,
    required double lat,
    required double lon,
    String? postcode,
  }) async {
    frost = profile.withYear(_year);
    regionName = name;
    frostSource = 'open-meteo';
    final existing = await gardens();
    if (existing.isNotEmpty) {
      await (db.update(db.gardens)..where((t) => t.id.equals(existing.first.id)))
          .write(GardensCompanion(
        lat: Value(lat),
        lon: Value(lon),
        postcode: Value(postcode),
        dirty: const Value(true),
      ));
    }
    notifyListeners();
  }

  /// Where the current frost dates came from, for the "based on" row (3.3).
  String frostSource = 'preset';

  Future<String> createGarden({
    required FrostRegion region,
    required GardenKind kind,
    int? sunHours,
    String name = 'My garden',
    int? sizeM2,
    String? postcode,
    FrostProfile? profile,
    double? lat,
    double? lon,
  }) async {
    frost = (profile ?? region.profile).withYear(_year);
    regionName = region.name;
    final id = newUuid();
    await db.into(db.gardens).insert(GardensCompanion.insert(
          id: id,
          owner: owner,
          name: name,
          kind: kind,
          sunHours: Value(sunHours),
          lat: Value(lat ?? region.lat),
          lon: Value(lon ?? region.lon),
          sizeM2: Value(sizeM2),
          postcode: Value(postcode),
          dirty: const Value(true),
        ));
    notifyListeners();
    return id;
  }

  Future<String> addPlant({
    required String gardenId,
    required String cropSlug,
    int? potLitres,
    String? plantedOn,
    MethodType? method,
    String? varietySlug,
    String? place,
  }) async {
    final id = newUuid();
    await db.into(db.gardenPlants).insert(GardenPlantsCompanion.insert(
          id: id,
          owner: owner,
          gardenId: gardenId,
          cropSlug: cropSlug,
          potLitres: Value(potLitres),
          varietySlug: Value(varietySlug),
          place: Value(place),
          dirty: const Value(true),
        ));
    if (plantedOn != null) await startGrowing(id, method: method, on: plantedOn);
    notifyListeners();
    return id;
  }

  // ── Timeline path (PRD §7) ─────────────────────────────────────────────
  static TaskKind _taskKindFor(NodeKind k) => switch (k) {
        NodeKind.sow => TaskKind.sow,
        NodeKind.potOn => TaskKind.potOn,
        NodeKind.transplant => TaskKind.transplant,
        NodeKind.thin => TaskKind.thin,
        NodeKind.feed => TaskKind.feed,
        NodeKind.water => TaskKind.water,
        NodeKind.harvest => TaskKind.harvest,
        NodeKind.harvested => TaskKind.harvest,
      };

  Future<void> _clearPath(String plantId) async {
    await (db.update(db.tasks)
          ..where((t) => t.gardenPlantId.equals(plantId) & t.nodeKind.isNotNull()))
        .write(TasksCompanion(deletedAt: Value(DateTime.now()), dirty: const Value(true)));
  }

  Future<void> _rebuildPath(String plantId, Crop crop, MethodType method, String on) async {
    await _clearPath(plantId);
    final nodes = buildPath(crop, PathStart(method: method, on: on), plantId);
    await db.batch((b) {
      for (final n in nodes) {
        b.insert(
          db.tasks,
          TasksCompanion.insert(
            // Node ids are deterministic per plant; a rebuild reuses them.
            id: n.id,
            owner: owner,
            gardenPlantId: Value(plantId),
            kind: _taskKindFor(n.kind),
            due: n.due,
            nodeKind: Value(nodeKindToWire(n.kind)),
            plannedDue: Value(n.plannedDue),
            completedAt: const Value(null),
            movedReason: const Value(null),
            skipped: const Value(false),
            deletedAt: const Value(null),
            dirty: const Value(true),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  PathNode _nodeFromRow(TaskRow r, Crop? crop) {
    final kind = nodeKindFromWire(r.nodeKind!);
    // `until` is not a server column: the harvest window length is a crop fact.
    String? until;
    if (kind == NodeKind.harvest && crop != null) {
      until = toIso(addDays(parseIso(r.due), crop.harvestDaysMax - crop.harvestDaysMin));
    }
    return PathNode(
      id: r.id,
      kind: kind,
      plannedDue: r.plannedDue ?? r.due,
      due: r.due,
      until: until,
      loggedOn: r.completedAt == null ? null : toIso(r.completedAt!.toUtc()),
      skipped: r.skipped,
      movedReason: r.movedReason == null
          ? null
          : LocalizedText.fromJson(jsonDecode(r.movedReason!) as Map<String, dynamic>),
    );
  }

  /// The plant's path, past to future. Empty while planning.
  Future<List<PathNode>> pathFor(String plantId) async {
    final plant = await plantById(plantId);
    final crop = plant == null ? null : cropBySlug(plant.cropSlug);
    final rows = await (db.select(db.tasks)
          ..where((t) => t.gardenPlantId.equals(plantId) & t.nodeKind.isNotNull() & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.due), (t) => OrderingTerm.asc(t.plannedDue)]))
        .get();
    return [for (final r in rows) _nodeFromRow(r, crop)];
  }

  /// Log a node as done on [loggedOn] and re-derive downstream nodes
  /// (§7.2). Returns the engine result so the UI can show "moved, not behind".
  Future<ReplanResult> logNode(String plantId, String nodeId, String loggedOn) async {
    final path = await pathFor(plantId);
    final result = engine.logNode(path, nodeId, loggedOn, params: ReplanParams(firstFrost: frost.firstFrost));
    final before = {for (final n in path) n.id: n};
    await db.batch((b) {
      for (final n in result.nodes) {
        final was = before[n.id]!;
        final changed = n.id == nodeId || n.due != was.due || n.movedReason != was.movedReason;
        if (!changed) continue;
        b.update(
          db.tasks,
          TasksCompanion(
            due: Value(n.due),
            completedAt: n.id == nodeId ? Value(parseIso(loggedOn)) : const Value.absent(),
            movedReason: Value(n.movedReason == null ? null : jsonEncode(n.movedReason!.toJson())),
            dirty: const Value(true),
          ),
          where: (t) => t.id.equals(n.id),
        );
      }
    });
    if (nodeId.endsWith('-harvest')) await _setStage(plantId, 'harvesting', loggedOn);
    if (nodeId.endsWith('-transplant')) await _setStage(plantId, 'vegetative', loggedOn);
    notifyListeners();
    return result;
  }

  /// Skip a node with a reason (rain counts as a completed day for streaks).
  Future<void> skipNode(String nodeId, LocalizedText reason) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(nodeId))).write(
      TasksCompanion(
        skipped: const Value(true),
        movedReason: Value(jsonEncode(reason.toJson())),
        dirty: const Value(true),
      ),
    );
    notifyListeners();
  }

  Future<void> _setStage(String plantId, String stage, String on) =>
      (db.update(db.gardenPlants)..where((t) => t.id.equals(plantId))).write(
        GardenPlantsCompanion(stage: Value(stage), stageChangedOn: Value(on), dirty: const Value(true)),
      );

  Future<void> setStage(String plantId, String stage) async {
    await _setStage(plantId, stage, today);
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

  /// Regenerate the client-owned watering tasks for `[today, today+7)`.
  /// Sow / transplant / feed / harvest come from the plant's path, so they are
  /// not generated here. Stable ids + insert-or-ignore preserve completions.
  Future<void> _regenerateTasks() async {
    final active = await growingPlants();
    for (final plant in active) {
      final crop = cropBySlug(plant.cropSlug);
      for (final wt in wateringTasksFor(
        plantId: plant.id,
        cropSlug: plant.cropSlug,
        potLitres: plant.potLitres,
        today: today,
        cadence: crop?.waterCadenceDays,
      )) {
        await db.into(db.tasks).insert(
              TasksCompanion.insert(
                id: wt.id,
                owner: owner,
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
    // Waterings in the window; path nodes in the window plus any still-open
    // node from before today (it is "current", never "overdue").
    final rows = await (db.select(db.tasks)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.skipped.equals(false) &
              t.due.isSmallerThanValue(end) &
              (t.due.isBiggerOrEqualValue(today) |
                  (t.nodeKind.isNotNull() & t.completedAt.isNull()))))
        .get();

    // Weather hints (F4): the overlay runs on-device over live observations
    // for the garden's coordinate. No observations → no hints, never invented.
    final gardenRows = await gardens();
    final lat = gardenRows.isEmpty ? null : gardenRows.first.lat;
    final lon = gardenRows.isEmpty ? null : gardenRows.first.lon;
    final obs = lat == null || lon == null ? null : await _observations(lat, lon);
    lastObservations = obs;
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
      if (obs != null)
        for (final a in adjustTasks(timingTasks, obs, params: defaultAdjust.withToday(today)))
          a.taskId: a,
    };

    final items = <ThisWeekItem>[
      for (final r in rows)
        if (plantById[r.gardenPlantId] != null)
          ThisWeekItem(
            taskId: r.id,
            plantId: r.gardenPlantId,
            cropSlug: plantById[r.gardenPlantId]!.cropSlug,
            cropNames: cropNames(plantById[r.gardenPlantId]!.cropSlug),
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
    final row = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
    if (completed && row?.nodeKind != null && row?.gardenPlantId != null) {
      await logNode(row!.gardenPlantId!, taskId, today);
      return;
    }
    await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        completedAt: Value(completed ? DateTime.now() : null),
        dirty: const Value(true),
      ),
    );
    notifyListeners();
  }

  // ── Streak (PRD 7.3) ───────────────────────────────────────────────────
  /// Days with ≥1 task completed or explicitly skipped, as ISO dates.
  Future<Set<String>> activeDays() async {
    final rows = await (db.select(db.tasks)
          ..where((t) => t.deletedAt.isNull() & (t.completedAt.isNotNull() | t.skipped.equals(true))))
        .get();
    return {
      for (final r in rows)
        if (r.completedAt != null) toIso(r.completedAt!.toUtc()) else r.due,
    };
  }

  /// Streak ending today; persists the count on the profile for sync.
  Future<StreakResult> streak({bool premium = false}) async {
    final result = computeStreak(
      await activeDays(),
      today,
      params: StreakParams(freezesPerMonth: premium ? null : 2),
    );
    final p = await profile();
    if (p != null && p.streakCount != result.count) {
      await (db.update(db.profiles)..where((t) => t.id.equals(owner))).write(
        ProfilesCompanion(streakCount: Value(result.count), dirty: const Value(true)),
      );
    }
    return result;
  }

  // ── Journal (F5) ───────────────────────────────────────────────────────
  Future<List<JournalEntryRow>> journal(String plantId) =>
      (db.select(db.journalEntries)
            ..where((t) => t.gardenPlantId.equals(plantId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.entryOn)]))
          .get();

  /// Growth log (PRD 5.5): mood 1 (bad) … 4 (excellent), up to 9 photos
  /// (local paths; uploaded to Storage once the bucket is live), a note, and
  /// the stage at the time — which also updates the plant's stage.
  Future<void> addJournalEntry({
    required String plantId,
    String note = '',
    int? mood,
    String? stage,
    List<String> photoPaths = const [],
    String? entryOn,
  }) async {
    await db.into(db.journalEntries).insert(JournalEntriesCompanion.insert(
          id: newUuid(),
          owner: owner,
          gardenPlantId: Value(plantId),
          entryOn: entryOn ?? today,
          note: Value(note.isEmpty ? null : note),
          photoPath: Value(photoPaths.isEmpty ? null : photoPaths.first),
          mood: Value(mood),
          stage: Value(stage),
          photoPaths: Value(jsonEncode(photoPaths)),
          dirty: const Value(true),
        ));
    if (stage != null) await _setStage(plantId, stage, entryOn ?? today);
    notifyListeners();
  }

  // ── Harvest (PRD 7.5) ──────────────────────────────────────────────────
  Future<List<HarvestRow>> harvests() => (db.select(db.harvests)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.harvestedOn)]))
      .get();

  /// Shop value of one harvest from the price table; null when unpriced.
  double? harvestValue(HarvestRow r) {
    final p = content.prices[r.cropSlug];
    if (p == null || p.unit != r.unit) return null;
    return p.eur * r.quantity;
  }

  /// Season payoff: summed value (priced rows) and the yield tally per unit.
  Future<({double euros, double kg, double pcs, int unpriced})> seasonTally() async {
    var euros = 0.0, kg = 0.0, pcs = 0.0, unpriced = 0;
    for (final r in await harvests()) {
      final v = harvestValue(r);
      if (v == null) {
        unpriced++;
      } else {
        euros += v;
      }
      if (r.unit == 'kg') {
        kg += r.quantity;
      } else {
        pcs += r.quantity;
      }
    }
    return (euros: euros, kg: kg, pcs: pcs, unpriced: unpriced);
  }

  Future<double> seasonHarvestValue() async => (await seasonTally()).euros;

  Future<void> logHarvest({
    required String cropSlug,
    String? plantId,
    required double quantity,
    String unit = 'pcs',
    String? harvestedOn,
  }) async {
    final label = '${quantity % 1 == 0 ? quantity.toInt() : quantity} ${unit == 'kg' ? 'kg' : 'pcs'}';
    await db.into(db.harvests).insert(HarvestsCompanion.insert(
          id: newUuid(),
          owner: owner,
          gardenPlantId: Value(plantId),
          cropSlug: cropSlug,
          amount: label,
          quantity: Value(quantity),
          unit: Value(unit),
          harvestedOn: harvestedOn ?? today,
          dirty: const Value(true),
        ));
    if (plantId != null) await _setStage(plantId, 'harvesting', harvestedOn ?? today);
    notifyListeners();
  }

  // ── Feedback (PRD 2.7 / 3.9) ───────────────────────────────────────────
  Future<void> addFeedback({
    required String targetKind,
    required String targetId,
    required String sentiment,
    String? body,
  }) async {
    await db.into(db.feedback).insert(FeedbackCompanion.insert(
          id: newUuid(),
          owner: owner,
          targetKind: targetKind,
          targetId: targetId,
          sentiment: sentiment,
          body: Value(body),
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
