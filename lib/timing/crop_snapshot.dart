/// Parsing for the bundled crop snapshot (`assets/data/crops-snapshot.json`).
///
/// The file is byte-identical in shape to the `GET /api/crops` response, so one
/// parser handles both the bundled cold-start path and the online delta sync
/// (API contract section 2). `version` is a content hash the client stores and
/// sends back as `If-None-Match` to get a `304` when nothing changed.
library;

import 'dart:convert';

import 'types.dart';

class CropSnapshot {
  const CropSnapshot({
    required this.version,
    required this.generatedAt,
    required this.crops,
    required this.deleted,
  });

  final String version;
  final String generatedAt;
  final List<Crop> crops;
  final List<String> deleted;

  factory CropSnapshot.fromJson(Map<String, dynamic> j) => CropSnapshot(
        version: j['version'] as String,
        generatedAt: j['generated_at'] as String,
        crops: (j['crops'] as List)
            .map((c) => Crop.fromJson(c as Map<String, dynamic>))
            .toList(growable: false),
        deleted: (j['deleted'] as List? ?? const [])
            .map((s) => s as String)
            .toList(growable: false),
      );

  static CropSnapshot parse(String jsonText) =>
      CropSnapshot.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
}
