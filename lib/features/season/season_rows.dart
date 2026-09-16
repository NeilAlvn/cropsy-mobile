/// The season path's shape, as data.
///
/// Which months appear, where today sits, and which empty month earns a
/// suggestion is the only real logic on the screen, so it lives here as a pure
/// function over the nodes and gets tested on its own.
library;

import '../../timing/dates.dart';
import '../../timing/season.dart';
import 'season_markers.dart';

enum SeasonRowKind { month, today, node, task, marker, suggestion }

/// A plant's own pending step, as the path needs it. The screen fills this
/// from the repository; the shape function only needs its date.
class SeasonTask {
  const SeasonTask({
    required this.nodeId,
    required this.plantId,
    required this.cropSlug,
    required this.kind,
    required this.due,
    required this.title,
  });

  final String nodeId;
  final String plantId;
  final String cropSlug;

  /// The node kind's name, which is also its badge asset.
  final String kind;
  final String due;
  final String title;
}

class SeasonRow {
  const SeasonRow.month(this.month, {required this.current})
      : kind = SeasonRowKind.month,
        node = null,
        marker = null,
        task = null,
        count = 0;
  const SeasonRow.today()
      : kind = SeasonRowKind.today,
        month = 0,
        node = null,
        marker = null,
        task = null,
        count = 0,
        current = false;
  const SeasonRow.node(this.node, this.month)
      : kind = SeasonRowKind.node,
        marker = null,
        task = null,
        count = 0,
        current = false;
  const SeasonRow.marker(this.marker, this.month)
      : kind = SeasonRowKind.marker,
        node = null,
        task = null,
        count = 0,
        current = false;
  const SeasonRow.task(this.task, this.month)
      : kind = SeasonRowKind.task,
        node = null,
        marker = null,
        count = 0,
        current = false;
  const SeasonRow.suggestion(this.month, this.count)
      : kind = SeasonRowKind.suggestion,
        node = null,
        marker = null,
        task = null,
        current = false;

  final SeasonRowKind kind;
  final int month;
  final SeasonNode? node;
  final SeasonMarker? marker;
  final SeasonTask? task;
  final int count;
  final bool current;
}

/// Builds the path.
///
/// - A month with nodes is a section with those nodes, in date order.
/// - An empty month from today onwards carries a suggestion, counted by
///   [optionsFor], so the path never dead-ends in the quiet half of the year.
/// - An empty past month is dropped, so the path opens tight.
/// - Today is marked once, inside its own month, before the first node that
///   comes after it.
List<SeasonRow> seasonRows({
  required List<SeasonNode> nodes,
  required DateTime today,
  required int Function(int month) optionsFor,
  List<SeasonMarker> markers = const [],
  List<SeasonTask> tasks = const [],
}) {
  final byMonth = <int, List<SeasonNode>>{};
  for (final n in [...nodes]..sort((a, b) => a.start.compareTo(b.start))) {
    byMonth.putIfAbsent(parseIso(n.start).month, () => []).add(n);
  }
  final markersByMonth = <int, List<SeasonMarker>>{};
  for (final m in [...markers]..sort((a, b) => a.on.compareTo(b.on))) {
    markersByMonth.putIfAbsent(parseIso(m.on).month, () => []).add(m);
  }
  final tasksByMonth = <int, List<SeasonTask>>{};
  for (final t in [...tasks]..sort((a, b) => a.due.compareTo(b.due))) {
    tasksByMonth.putIfAbsent(parseIso(t.due).month, () => []).add(t);
  }

  final rows = <SeasonRow>[];
  var markedToday = false;
  for (var month = 1; month <= 12; month++) {
    final inMonth = byMonth[month] ?? const <SeasonNode>[];
    final marks = markersByMonth[month] ?? const <SeasonMarker>[];
    final steps = tasksByMonth[month] ?? const <SeasonTask>[];
    final empty = inMonth.isEmpty && marks.isEmpty && steps.isEmpty;
    final suggestion = empty && month >= today.month ? optionsFor(month) : 0;
    if (empty && suggestion == 0 && month != today.month) continue;

    rows.add(SeasonRow.month(month, current: month == today.month));

    // Nodes and markers share one timeline inside the month, so a frost date
    // lands between the sowings it actually falls between.
    final dated = <({String on, SeasonNode? node, SeasonMarker? marker, SeasonTask? task})>[
      for (final n in inMonth) (on: n.start, node: n, marker: null, task: null),
      for (final m in marks) (on: m.on, node: null, marker: m, task: null),
      for (final t in steps) (on: t.due, node: null, marker: null, task: t),
    ]..sort((a, b) => a.on.compareTo(b.on));

    for (final entry in dated) {
      if (!markedToday && parseIso(entry.on).isAfter(today)) {
        rows.add(const SeasonRow.today());
        markedToday = true;
      }
      rows.add(switch (entry) {
        (:final node?, :final marker, :final task, on: _) when marker == null && task == null =>
          SeasonRow.node(node, month),
        (:final marker?, node: _, task: _, on: _) => SeasonRow.marker(marker, month),
        (:final task?, node: _, marker: _, on: _) => SeasonRow.task(task, month),
        _ => throw StateError('a path entry with nothing in it'),
      });
    }
    if (suggestion > 0) rows.add(SeasonRow.suggestion(month, suggestion));
    if (!markedToday && month >= today.month) {
      rows.add(const SeasonRow.today());
      markedToday = true;
    }
  }
  if (!markedToday) rows.add(const SeasonRow.today());
  return rows;
}
