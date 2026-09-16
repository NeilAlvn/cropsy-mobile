import 'package:cropsy/features/season/season_rows.dart';
import 'package:cropsy/timing/season.dart';
import 'package:flutter_test/flutter_test.dart';

SeasonNode _node(String start, String end, String slug) => SeasonNode(
      kind: SeasonNodeKind.sowWindow,
      cropSlug: slug,
      plantId: 'p-$slug',
      start: start,
      end: end,
    );

void main() {
  final today = DateTime.utc(2026, 9, 16);
  List<SeasonRow> build(List<SeasonNode> nodes, {int options = 8}) => seasonRows(
        nodes: nodes,
        today: today,
        optionsFor: (_) => options,
      );

  test('an empty past month is dropped, a busy one is kept', () {
    final rows = build([_node('2026-05-13', '2026-05-27', 'basil')]);
    final months = rows
        .where((r) => r.kind == SeasonRowKind.month)
        .map((r) => r.month)
        .toList();
    expect(months, contains(5));
    expect(months, isNot(contains(2)));
  });

  test('today is marked once, inside its own month, before later nodes', () {
    final rows = build([
      _node('2026-05-13', '2026-05-27', 'basil'),
      _node('2026-10-24', '2026-11-13', 'lettuce'),
    ]);
    expect(rows.where((r) => r.kind == SeasonRowKind.today), hasLength(1));

    final todayAt = rows.indexWhere((r) => r.kind == SeasonRowKind.today);
    final octoberAt = rows.indexWhere(
        (r) => r.kind == SeasonRowKind.month && r.month == 10);
    final mayNodeAt = rows.indexWhere((r) => r.kind == SeasonRowKind.node);
    expect(todayAt, greaterThan(mayNodeAt));
    expect(todayAt, lessThan(octoberAt));
  });

  test('an empty future month suggests, an empty past month does not', () {
    final rows = build(const []);
    final suggested = rows
        .where((r) => r.kind == SeasonRowKind.suggestion)
        .map((r) => r.month)
        .toList();
    expect(suggested, [9, 10, 11, 12]);
    expect(rows.firstWhere((r) => r.kind == SeasonRowKind.suggestion).count, 8);
  });

  test('a month with nothing to offer does not become a section', () {
    final rows = build(const [], options: 0);
    final months = rows
        .where((r) => r.kind == SeasonRowKind.month)
        .map((r) => r.month)
        .toList();
    // Only the current month survives, so the path still says where you are.
    expect(months, [9]);
  });
}
