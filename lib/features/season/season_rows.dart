/// The season path's shape, as data.
///
/// Which months appear, where today sits, and which empty month earns a
/// suggestion is the only real logic on the screen, so it lives here as a pure
/// function over the nodes and gets tested on its own.
library;

import '../../timing/dates.dart';
import '../../timing/season.dart';

enum SeasonRowKind { month, today, node, suggestion }

class SeasonRow {
  const SeasonRow.month(this.month, {required this.current})
      : kind = SeasonRowKind.month,
        node = null,
        count = 0;
  const SeasonRow.today()
      : kind = SeasonRowKind.today,
        month = 0,
        node = null,
        count = 0,
        current = false;
  const SeasonRow.node(this.node, this.month)
      : kind = SeasonRowKind.node,
        count = 0,
        current = false;
  const SeasonRow.suggestion(this.month, this.count)
      : kind = SeasonRowKind.suggestion,
        node = null,
        current = false;

  final SeasonRowKind kind;
  final int month;
  final SeasonNode? node;
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
}) {
  final byMonth = <int, List<SeasonNode>>{};
  for (final n in [...nodes]..sort((a, b) => a.start.compareTo(b.start))) {
    byMonth.putIfAbsent(parseIso(n.start).month, () => []).add(n);
  }

  final rows = <SeasonRow>[];
  var markedToday = false;
  for (var month = 1; month <= 12; month++) {
    final inMonth = byMonth[month] ?? const <SeasonNode>[];
    final suggestion =
        inMonth.isEmpty && month >= today.month ? optionsFor(month) : 0;
    if (inMonth.isEmpty && suggestion == 0 && month != today.month) continue;

    rows.add(SeasonRow.month(month, current: month == today.month));
    for (final n in inMonth) {
      if (!markedToday && parseIso(n.start).isAfter(today)) {
        rows.add(const SeasonRow.today());
        markedToday = true;
      }
      rows.add(SeasonRow.node(n, month));
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
