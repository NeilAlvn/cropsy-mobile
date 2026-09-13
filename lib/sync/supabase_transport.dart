/// Supabase (PostgREST) implementation of [SyncTransport]. RLS scopes every
/// query to the signed-in user; the owner filter is belt-and-braces.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_engine.dart';

class SupabaseTransport implements SyncTransport {
  SupabaseTransport(this.client);
  final SupabaseClient client;

  @override
  Future<List<Map<String, dynamic>>> pull(String table, String owner, String? since, {int limit = 500}) async {
    var q = client.from(table).select().eq('owner', owner);
    if (since != null) q = q.gt('updated_at', since);
    final rows = await q.order('updated_at', ascending: true).limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> push(String table, List<Map<String, dynamic>> rows) =>
      client.from(table).upsert(rows, onConflict: 'id');
}
