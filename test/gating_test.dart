import 'package:cropsy/features/garden/gating.dart';
import 'package:cropsy/features/season/season_rows.dart';
import 'package:cropsy/timing/season.dart';
import 'package:flutter_test/flutter_test.dart';

SeasonNode _node(String start, String slug) => SeasonNode(
      kind: SeasonNodeKind.sowWindow,
      cropSlug: slug,
      plantId: 'p-$slug',
      start: start,
      end: start,
    );

void main() {
  test('free gardens stop at three growing plants', () {
    expect(overPlantLimit(2, premium: false), isFalse);
    expect(overPlantLimit(3, premium: false), isTrue);
    expect(overPlantLimit(9, premium: true), isFalse);
  });

  test('home card rests seven days after it shows', () {
    expect(homeCardDue(null, '2026-10-12'), isTrue);
    expect(homeCardDue('2026-10-06', '2026-10-12'), isFalse);
    expect(homeCardDue('2026-10-05', '2026-10-12'), isTrue);
  });

  group('free season path', () {
    final today = DateTime.utc(2026, 4, 10);
    List<SeasonRow> rows(List<SeasonNode> nodes) => seasonRows(nodes: nodes, today: today, optionsFor: (_) => 0);

    test('locks from the first row two weeks out', () {
      final r = rows([_node('2026-04-01', 'a'), _node('2026-04-23', 'b'), _node('2026-04-24', 'c'), _node('2026-05-02', 'd')]);
      final at = seasonLockFrom(r, today)!;
      expect(r[at].node?.cropSlug, 'c');
      expect(r.take(at).any((x) => x.kind == SeasonRowKind.today), isTrue);
    });

    test('a later month header is where the lock starts', () {
      final r = rows([_node('2026-04-12', 'a'), _node('2026-05-20', 'b')]);
      final at = seasonLockFrom(r, today)!;
      expect(r[at].kind, SeasonRowKind.month);
      expect(r[at].month, 5);
    });

    test('nothing to lock inside the two weeks', () {
      expect(seasonLockFrom(rows([_node('2026-04-12', 'a')]), today), isNull);
    });
  });
}
