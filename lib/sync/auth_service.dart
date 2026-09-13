/// Anonymous-first auth (PRD Phase 1): the app works with a local owner id;
/// signing in (magic link or password) re-labels every local row with the
/// auth uid and syncs. Sign-out keeps local data and stops syncing.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../features/garden/garden_repository.dart';
import 'photo_uploader.dart';
import 'supabase_transport.dart';
import 'sync_engine.dart';

class AuthService extends ChangeNotifier {
  AuthService(this.repo) {
    _sub = _client.auth.onAuthStateChange.listen((s) async {
      if (s.event == AuthChangeEvent.signedIn || s.event == AuthChangeEvent.initialSession) {
        final uid = s.session?.user.id;
        if (uid != null) await _adopt(uid);
      }
      notifyListeners();
    });
  }

  final GardenRepository repo;
  SupabaseClient get _client => Supabase.instance.client;
  late final StreamSubscription<AuthState> _sub;

  bool syncing = false;
  SyncReport? lastReport;
  DateTime? lastSyncAt;

  User? get user => _client.auth.currentUser;
  bool get signedIn => user != null;

  static Future<void> init() => Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  Future<void> sendMagicLink(String email) =>
      _client.auth.signInWithOtp(email: email, emailRedirectTo: authRedirect);

  Future<void> signInWithPassword(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signUp(String email, String password) =>
      _client.auth.signUp(email: email, password: password, emailRedirectTo: authRedirect);

  Future<void> signOut() async {
    await _client.auth.signOut();
    notifyListeners();
  }

  Future<void> _adopt(String uid) async {
    if (repo.owner != uid) await repo.adoptOwner(uid);
    await syncNow();
  }

  Future<SyncReport?> syncNow() async {
    if (!signedIn || syncing) return null;
    syncing = true;
    notifyListeners();
    try {
      // Photos first: the row then pushes storage keys instead of local paths.
      await PhotoUploader(repo.db, _client).uploadPending(repo.owner);
      final report = await SyncEngine(repo.db, SupabaseTransport(_client)).sync(repo.owner);
      lastReport = report;
      lastSyncAt = DateTime.now();
      repo.notifyListeners();
      return report;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  /// PRD 8.2 "Delete account": server route removes the auth user (cascades
  /// to every owned row); local data is wiped by the caller.
  Future<bool> deleteAccount() async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) return false;
    final http = HttpClient();
    final req = await http.deleteUrl(Uri.parse('$apiBaseUrl/api/account'));
    req.headers.set('authorization', 'Bearer $token');
    final res = await req.close();
    await res.drain<void>();
    http.close();
    if (res.statusCode == 204) {
      await _client.auth.signOut();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
