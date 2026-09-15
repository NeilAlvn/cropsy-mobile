/// Client for the Phase 4 proxies: POST /api/identify and /api/diagnose.
/// Multipart photo + the Supabase JWT. Every answer is a guess; the UI says so.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

class ScanSuggestion {
  const ScanSuggestion({required this.name, required this.score, this.latin, this.cropSlug, this.problemSlug});
  final String name;
  final double score;
  final String? latin;
  final String? cropSlug;
  final String? problemSlug;
}

class ScanResult {
  const ScanResult({required this.suggestions, this.reason, this.healthy, this.disclaimer, this.used, this.limit});
  final List<ScanSuggestion> suggestions;

  /// `no_match`, `not_a_plant`, or null.
  final String? reason;
  final bool? healthy;
  final String? disclaimer;
  final int? used;
  final int? limit;
}

/// Thrown for every non-2xx answer; `code` is the server's error key.
class ScanException implements Exception {
  ScanException(this.code, this.status);
  final String code;
  final int status;
  bool get notConfigured => code == 'not_configured';
  bool get premiumRequired => code == 'premium_required';
  bool get quota => code == 'quota';
  @override
  String toString() => 'ScanException($code, $status)';
}

Future<ScanResult> _post(String path, File photo, String? token) async {
  if (token == null) throw ScanException('unauthorized', 401);
  final req = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl$path'))
    ..headers['authorization'] = 'Bearer $token'
    ..files.add(await http.MultipartFile.fromPath('image', photo.path, filename: 'photo.jpg'));
  final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 40)));
  final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode >= 300) throw ScanException(body['error'] as String? ?? 'http', res.statusCode);
  final list = (body['suggestions'] as List? ?? const []).cast<Map<String, dynamic>>();
  return ScanResult(
    suggestions: [
      for (final s in list)
        ScanSuggestion(
          name: s['name'] as String,
          score: (s['score'] as num).toDouble(),
          latin: s['latin'] as String?,
          cropSlug: s['crop_slug'] as String?,
          problemSlug: s['problem_slug'] as String?,
        ),
    ],
    reason: body['reason'] as String?,
    healthy: body['healthy'] as bool?,
    disclaimer: (body['disclaimer'] as Map?)?['en'] as String?,
    used: body['used'] as int?,
    limit: body['limit'] as int?,
  );
}

Future<ScanResult> identify(File photo, String? token) => _post('/api/identify', photo, token);
Future<ScanResult> diagnose(File photo, String? token) => _post('/api/diagnose', photo, token);
