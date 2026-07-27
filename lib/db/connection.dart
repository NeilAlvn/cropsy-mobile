/// On-device database connection. Opens the SQLite file in the app's documents
/// directory, off the UI isolate. Tests use `AppDatabase.memory()` instead, so
/// this file (and its path_provider dependency) never loads under `flutter test`.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart';

/// Build the app's database backed by a file in the documents directory.
AppDatabase openAppDatabase() {
  return AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'cropsy.sqlite'));
      return NativeDatabase.createInBackground(file);
    }),
  );
}
