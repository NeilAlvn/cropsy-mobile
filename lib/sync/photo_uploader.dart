/// Journal photos → Supabase Storage bucket `journal` (migration 0003).
///
/// `journal_entries.photo_paths` holds either a local absolute path (not yet
/// uploaded, or downloaded cache) or a storage key `<uid>/<uuid>.jpg`. Upload
/// runs on sign-in sync and after each new entry; download is lazy, on view.
/// Offline: nothing happens, local paths keep working.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/database.dart';

class PhotoUploader {
  PhotoUploader(this.db, this.client);
  final AppDatabase db;
  final SupabaseClient client;

  static const bucket = 'journal';
  static bool isKey(String s) => !s.startsWith('/');

  /// Upload every local photo of every journal row owned by [uid]; rewrite
  /// the row with storage keys and mark it dirty so the sync pushes them.
  Future<int> uploadPending(String uid) async {
    final rows = await (db.select(db.journalEntries)
          ..where((t) => t.deletedAt.isNull() & t.owner.equals(uid) & t.photoPaths.like('%"/%')))
        .get();
    var uploaded = 0;
    for (final r in rows) {
      final paths = (jsonDecode(r.photoPaths) as List).cast<String>();
      final next = <String>[];
      var changed = false;
      for (final path in paths) {
        if (isKey(path) || !File(path).existsSync()) {
          next.add(path);
          continue;
        }
        final key = '$uid/${p.basename(path)}';
        try {
          await client.storage.from(bucket).upload(key, File(path), fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
          // Keep the bytes locally under the key's name so display needs no download.
          await _cacheFile(key, File(path));
          next.add(key);
          changed = true;
          uploaded++;
        } catch (_) {
          next.add(path); // offline or bucket missing: retry next sync
        }
      }
      if (changed) {
        await (db.update(db.journalEntries)..where((t) => t.id.equals(r.id))).write(
          JournalEntriesCompanion(
            photoPaths: Value(jsonEncode(next)),
            photoPath: Value(next.isEmpty ? null : next.first),
            dirty: const Value(true),
          ),
        );
      }
    }
    return uploaded;
  }

  static Future<Directory> _cacheDir() async {
    final d = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'journal-cache'));
    await d.create(recursive: true);
    return d;
  }

  static Future<File> _cacheFile(String key, File src) async {
    final dest = File(p.join((await _cacheDir()).path, key.replaceAll('/', '_')));
    if (!dest.existsSync()) await src.copy(dest.path);
    return dest;
  }

  /// Local file for a photo entry: the path itself, the cache, or a download.
  static Future<File?> localFile(String pathOrKey) async {
    if (!isKey(pathOrKey)) {
      final f = File(pathOrKey);
      return f.existsSync() ? f : null;
    }
    final cached = File(p.join((await _cacheDir()).path, pathOrKey.replaceAll('/', '_')));
    if (cached.existsSync()) return cached;
    try {
      final bytes = await Supabase.instance.client.storage.from(bucket).download(pathOrKey);
      await cached.writeAsBytes(bytes);
      return cached;
    } catch (_) {
      return null;
    }
  }
}
