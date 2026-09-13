/// Outbox push + delta pull (API-CONTRACT §6). Transport-agnostic so the
/// engine is unit-tested against an in-memory fake; production plugs in
/// Supabase via `supabase_transport.dart`.
///
/// Conflict policy: unsynced local edits win (a dirty local row is never
/// overwritten by a pull); everything else is last-write-wins on the server's
/// `updated_at`. Soft deletes travel as tombstones. Per-table failures are
/// reported, never fatal — a missing server table (migration not yet applied)
/// must not block the others.
library;

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'wire.dart';

abstract class SyncTransport {
  /// Rows for [owner] with `updated_at > since` (null = everything),
  /// ascending by `updated_at`, at most [limit].
  Future<List<Map<String, dynamic>>> pull(String table, String owner, String? since, {int limit});

  /// Upsert by id.
  Future<void> push(String table, List<Map<String, dynamic>> rows);
}

class SyncReport {
  final pushed = <String, int>{};
  final pulled = <String, int>{};
  final errors = <String, Object>{};
  bool get ok => errors.isEmpty;

  @override
  String toString() => 'pushed $pushed pulled $pulled errors $errors';
}

class SyncEngine {
  SyncEngine(this.db, this.transport, {this.pageSize = 500});

  final AppDatabase db;
  final SyncTransport transport;
  final int pageSize;

  Future<SyncReport> sync(String owner) async {
    final report = SyncReport();
    for (final t in syncTables) {
      try {
        report.pushed[t.name] = await _push(t, owner);
        report.pulled[t.name] = await _pull(t, owner);
      } catch (e) {
        report.errors[t.name] = e;
      }
    }
    return report;
  }

  Future<int> _push(TableSync<dynamic> t, String owner) async {
    final wires = await t.dirtyWires(db, owner);
    if (wires.isEmpty) return 0;
    await transport.push(t.name, wires);
    await t.markClean(db, wires.map((w) => w['id'] as String));
    return wires.length;
  }

  Future<String?> _cursor(String table) async {
    final row = await (db.select(db.syncCursors)..where((c) => c.entity.equals(table))).getSingleOrNull();
    return row?.cursor;
  }

  Future<int> _pull(TableSync<dynamic> t, String owner) async {
    var since = await _cursor(t.name);
    var total = 0;
    while (true) {
      final page = await transport.pull(t.name, owner, since, limit: pageSize);
      for (final w in page) {
        final local = await t.localById(db, w['id'] as String);
        // A dirty local row has edits the server hasn't seen: keep them, the
        // next push carries them up (single-user app, last write wins).
        if (local.exists && local.dirty) continue;
        await t.upsertFromWire(db, w);
        total++;
      }
      if (page.isNotEmpty) {
        since = page.last['updated_at'] as String;
        await db.into(db.syncCursors).insert(
              SyncCursorsCompanion.insert(entity: t.name, cursor: Value(since)),
              mode: InsertMode.insertOrReplace,
            );
      }
      if (page.length < pageSize) break;
    }
    return total;
  }
}
