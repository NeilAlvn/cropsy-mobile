import 'package:cropsy/features/season/season_markers.dart';
import 'package:cropsy/features/season/season_rows.dart';
import 'package:cropsy/timing/content_snapshot.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

/// The test catalogue knows every slug, so a companion stop is never dropped
/// for want of a name. The "not in the catalogue" case gets its own test.
LocalizedText? _anyName(String slug) => LocalizedText(nl: slug, en: slug);

MarkerFacts _facts({
  int plants = 3,
  bool photo = false,
  double euros = 0,
  LocalizedText? weather,
  List<ChecklistItem> checklist = const [],
  List<({String slug, String on})> grown = const [],
  List<({String slug, LocalizedText title, bool draft})> collections = const [],
  Set<int> busy = const {},
  LocalizedText? Function(String slug) nameOf = _anyName,
  ({String slug, String on})? firstSow,
  List<({String slug, String on})> harvests = const [],
  List<({int days, String on})> streaks = const [],
  List<({String plantId, String firstOn, String lastOn})> photos = const [],
}) =>
    MarkerFacts(
      today: DateTime.utc(2026, 9, 16),
      frost: const FrostProfile(lastFrost: '2026-05-13', firstFrost: '2026-10-15'),
      plantCount: plants,
      photoThisMonth: photo,
      euros: euros,
      kilos: 0,
      weatherTitle: weather,
      weatherCaption:
          weather == null ? null : const LocalizedText(nl: 'omdat', en: 'because'),
      checklist: checklist,
      grown: grown,
      collections: collections,
      busyMonths: busy,
      nameOf: nameOf,
      firstSow: firstSow,
      harvests: harvests,
      streaks: streaks,
      photos: photos,
    );

/// [n] harvests of the same crop, one a day through June (at most 30).
List<({String slug, String on})> _picked(int n) => [
      for (var i = 0; i < n; i++)
        (slug: 'tomato', on: '2026-06-${(i + 1).toString().padLeft(2, '0')}'),
    ];

ChecklistItem _job(int month, String title, {String? link, bool draft = false}) =>
    ChecklistItem(
      month: month,
      title: LocalizedText(nl: title, en: title),
      body: const LocalizedText(nl: '', en: ''),
      link: link,
      draft: draft,
    );

({String slug, LocalizedText title, bool draft}) _list(String slug,
        {bool draft = false}) =>
    (slug: slug, title: LocalizedText(nl: slug, en: slug), draft: draft);

Set<SeasonMarkerKind> _kinds(List<SeasonMarker> m) => m.map((e) => e.kind).toSet();

List<SeasonMarker> _of(List<SeasonMarker> m, SeasonMarkerKind kind) =>
    m.where((e) => e.kind == kind).toList();

void main() {
  test('the year always carries its frost dates and its recap', () {
    final marks = seasonMarkers(_facts(plants: 0));
    expect(
      _kinds(marks),
      containsAll([
        SeasonMarkerKind.ijsheiligen,
        SeasonMarkerKind.lastFrost,
        SeasonMarkerKind.firstFrost,
        SeasonMarkerKind.recap,
      ]),
    );
    // With no plants there is nothing to order seed for, photograph or tally.
    expect(_kinds(marks), isNot(contains(SeasonMarkerKind.orderSeeds)));
    expect(_kinds(marks), isNot(contains(SeasonMarkerKind.photo)));
    expect(_kinds(marks), isNot(contains(SeasonMarkerKind.payoff)));
  });

  test('a garden with plants gets the seed order, the photo and the payoff', () {
    final marks = seasonMarkers(_facts());
    expect(_kinds(marks), containsAll([
      SeasonMarkerKind.orderSeeds,
      SeasonMarkerKind.photo,
      SeasonMarkerKind.payoff,
    ]));
    expect(marks.firstWhere((m) => m.kind == SeasonMarkerKind.photo).on, '2026-09-15');
    expect(marks.firstWhere((m) => m.kind == SeasonMarkerKind.payoff).on, '2026-10-15');
  });

  test('this month\'s photo, once taken, stops asking', () {
    expect(_kinds(seasonMarkers(_facts(photo: true))),
        isNot(contains(SeasonMarkerKind.photo)));
  });

  test('the payoff reads the tally when there is one', () {
    final marks = seasonMarkers(_facts(euros: 24.4));
    expect(marks.firstWhere((m) => m.kind == SeasonMarkerKind.payoff).caption.nl,
        contains('€24'));
    expect(marks.firstWhere((m) => m.kind == SeasonMarkerKind.payoff).caption.en,
        contains('€24'));
  });

  test('a weather change lands on today', () {
    final marks = seasonMarkers(_facts(
      weather: const LocalizedText(nl: 'Regen deed het', en: 'Rain did the watering'),
    ));
    final weather = marks.firstWhere((m) => m.kind == SeasonMarkerKind.weather);
    expect(weather.on, '2026-09-16');
  });

  // ── the content stops ─────────────────────────────────────────────────────

  test('with no content of its own, the path gains nothing new', () {
    final marks = seasonMarkers(_facts());
    expect(_kinds(marks), isNot(contains(SeasonMarkerKind.checklist)));
    expect(_kinds(marks), isNot(contains(SeasonMarkerKind.companion)));
    expect(_kinds(marks), isNot(contains(SeasonMarkerKind.collection)));
  });

  test('the month checklist lands in its own month, links and all', () {
    final marks = seasonMarkers(_facts(checklist: [
      _job(3, 'Chit the potatoes', link: 'potato'),
      _job(7, 'Water in the evening'),
    ]));
    final jobs = _of(marks, SeasonMarkerKind.checklist);
    expect(jobs.map((m) => m.on), ['2026-03-01', '2026-07-01']);
    expect(jobs.first.title.nl, 'Chit the potatoes');
    expect(jobs.first.slug, 'potato');
    expect(jobs.last.slug, isNull);
  });

  test('a month gets at most two checklist stops, in snapshot order', () {
    final marks = seasonMarkers(_facts(checklist: [
      _job(4, 'one'),
      _job(4, 'two'),
      _job(4, 'three'),
      _job(4, 'four'),
    ]));
    final jobs = _of(marks, SeasonMarkerKind.checklist);
    expect(jobs.map((m) => m.title.en), ['one', 'two']);
    // Consecutive days, so the section sort keeps the order they came in.
    expect(jobs.map((m) => m.on), ['2026-04-01', '2026-04-02']);
  });

  test('draft checklist rows stay off the path', () {
    final marks = seasonMarkers(_facts(checklist: [
      _job(4, 'unverified', draft: true),
      _job(4, 'verified'),
    ]));
    expect(_of(marks, SeasonMarkerKind.checklist).map((m) => m.title.en),
        ['verified']);
  });

  test('a crop still to sow gets one good neighbour it does not grow', () {
    final marks = seasonMarkers(_facts(grown: [
      (slug: 'tomato', on: '2026-10-01'),
    ]));
    final pairs = _of(marks, SeasonMarkerKind.companion);
    expect(pairs, hasLength(1));
    // Basil is tomato's first listed companion and is not on the path.
    expect(pairs.single.slug, 'basil');
    expect(pairs.single.on, '2026-10-01');
    expect(pairs.single.caption.en, contains('tomato'));
  });

  test('a partner already on the path is not suggested again', () {
    final marks = seasonMarkers(_facts(grown: [
      (slug: 'tomato', on: '2026-10-01'),
      (slug: 'basil', on: '2026-10-02'),
    ]));
    expect(_of(marks, SeasonMarkerKind.companion).map((m) => m.slug),
        isNot(contains('basil')));
  });

  test('a sowing that has already been does not suggest a neighbour', () {
    final marks = seasonMarkers(_facts(grown: [
      (slug: 'tomato', on: '2026-05-01'),
    ]));
    expect(_of(marks, SeasonMarkerKind.companion), isEmpty);
  });

  test('a partner the catalogue does not carry is skipped, not printed raw', () {
    final marks = seasonMarkers(_facts(
      grown: [(slug: 'tomato', on: '2026-10-01')],
      nameOf: (slug) => slug == 'tomato' ? _anyName(slug) : null,
    ));
    expect(_of(marks, SeasonMarkerKind.companion), isEmpty);
  });

  test('the season gets two companion stops at most, never one per pair', () {
    final marks = seasonMarkers(_facts(grown: [
      (slug: 'tomato', on: '2026-10-01'),
      (slug: 'cucumber', on: '2026-10-02'),
      (slug: 'pea', on: '2026-10-03'),
      (slug: 'cabbage', on: '2026-10-04'),
    ]));
    // Four crops, a dozen-odd pairings between them, two stops.
    expect(_of(marks, SeasonMarkerKind.companion), hasLength(2));
  });

  test('one collection stop, in the first thin month from today on', () {
    final marks = seasonMarkers(_facts(collections: [
      _list('balconies'),
      _list('fast'),
    ]));
    final lists = _of(marks, SeasonMarkerKind.collection);
    expect(lists, hasLength(1));
    // September already carries the photo marker and holds no plants of its
    // own, so the list thickens that month rather than opening a new one.
    expect(lists.single.on, '2026-09-15');
    expect(lists.single.slug, 'balconies');
  });

  test('the collection keeps out of busy months and off bare ones', () {
    final marks = seasonMarkers(
        _facts(collections: [_list('balconies')], busy: {9, 10}));
    // November has nothing on it: leaving it bare keeps its "still sowable"
    // chest, so the stop falls through to December, which has the recap.
    expect(_of(marks, SeasonMarkerKind.collection).single.on, '2026-12-15');
  });

  test('draft collections are not pointed at', () {
    final marks = seasonMarkers(_facts(collections: [_list('beta', draft: true)]));
    expect(_of(marks, SeasonMarkerKind.collection), isEmpty);
  });

  // ── the milestone stops ───────────────────────────────────────────────────

  test('a new gardener with no history gets no milestones at all', () {
    final marks = seasonMarkers(_facts(plants: 0));
    for (final kind in [
      SeasonMarkerKind.firstSow,
      SeasonMarkerKind.harvest,
      SeasonMarkerKind.streak,
      SeasonMarkerKind.photoCompare,
    ]) {
      expect(_of(marks, kind), isEmpty, reason: '$kind');
    }
  });

  test('the first sowing sits on the day it was logged and names its crop', () {
    final marks = seasonMarkers(
        _facts(firstSow: (slug: 'tomato', on: '2026-03-04')));
    final sow = _of(marks, SeasonMarkerKind.firstSow).single;
    expect(sow.on, '2026-03-04');
    expect(sow.slug, 'tomato');
    expect(sow.caption.en, contains('tomato'));
    expect(sow.caption.nl, contains('tomato'));
  });

  test('last season\'s first sowing belongs to last season', () {
    final marks = seasonMarkers(
        _facts(firstSow: (slug: 'tomato', on: '2025-03-04')));
    expect(_of(marks, SeasonMarkerKind.firstSow), isEmpty);
  });

  test('the first harvest is a milestone on its own', () {
    final marks = seasonMarkers(_facts(harvests: _picked(3)));
    final first = _of(marks, SeasonMarkerKind.harvest).single;
    expect(first.title.en, contains('1'));
    expect(first.on, '2026-06-01');
    expect(first.caption.en, contains('tomato'));
  });

  test('a good year shows the two most recent harvest milestones, not five',
      () {
    final marks = seasonMarkers(_facts(harvests: _picked(25)));
    final trophies = _of(marks, SeasonMarkerKind.harvest);
    // 1, 10 and 25 were all reached; the first is the one they have moved past.
    expect(trophies, hasLength(2));
    expect(trophies.map((m) => m.on), ['2026-06-10', '2026-06-25']);
    expect(trophies.last.title.en, contains('25'));
  });

  test('harvests count in the order they happened, whatever order they arrive',
      () {
    final marks = seasonMarkers(_facts(harvests: [
      (slug: 'bean', on: '2026-08-01'),
      (slug: 'tomato', on: '2026-06-01'),
    ]));
    final first = _of(marks, SeasonMarkerKind.harvest).single;
    expect(first.on, '2026-06-01');
    expect(first.caption.en, contains('tomato'));
  });

  test('only this year\'s harvests are counted', () {
    final marks = seasonMarkers(_facts(harvests: [
      (slug: 'tomato', on: '2025-06-01'),
      (slug: 'bean', on: '2026-08-01'),
    ]));
    final first = _of(marks, SeasonMarkerKind.harvest).single;
    // Last year's row neither numbers this year's first harvest nor shows up.
    expect(first.on, '2026-08-01');
    expect(first.title.en, contains('1'));
  });

  test('only the longest run reached stands on the path', () {
    final marks = seasonMarkers(_facts(streaks: [
      (days: 7, on: '2026-02-10'),
      (days: 30, on: '2026-03-05'),
    ]));
    final run = _of(marks, SeasonMarkerKind.streak).single;
    expect(run.on, '2026-03-05');
    expect(run.title.en, contains('30'));
    expect(run.title.nl, contains('30'));
  });

  test('the photo comparison picks the widest gap and names the older month',
      () {
    final marks = seasonMarkers(_facts(photos: [
      (plantId: 'p1', firstOn: '2026-08-02', lastOn: '2026-09-10'),
      (plantId: 'p2', firstOn: '2026-04-02', lastOn: '2026-09-12'),
    ]));
    final look = _of(marks, SeasonMarkerKind.photoCompare).single;
    expect(look.slug, 'p2');
    // It sits on this month's picture, captioned with the older one's month.
    expect(look.on, '2026-09-12');
    expect(look.caption.en, contains('April'));
    expect(look.caption.nl, contains('april'));
  });

  test('a photo needs an older month to stand beside', () {
    final marks = seasonMarkers(_facts(photos: [
      // Both this month: nothing has changed worth looking at.
      (plantId: 'p1', firstOn: '2026-09-02', lastOn: '2026-09-14'),
      // Nothing this month: the plant was last photographed in August.
      (plantId: 'p2', firstOn: '2026-05-02', lastOn: '2026-08-14'),
    ]));
    expect(_of(marks, SeasonMarkerKind.photoCompare), isEmpty);
  });

  test('a full year of history still adds only five stops', () {
    final marks = seasonMarkers(_facts(
      firstSow: (slug: 'tomato', on: '2026-03-04'),
      harvests: _picked(25),
      streaks: [(days: 7, on: '2026-02-10'), (days: 30, on: '2026-03-05')],
      photos: [(plantId: 'p1', firstOn: '2026-04-02', lastOn: '2026-09-12')],
    ));
    final milestones = marks.where((m) => const {
          SeasonMarkerKind.firstSow,
          SeasonMarkerKind.harvest,
          SeasonMarkerKind.streak,
          SeasonMarkerKind.photoCompare,
        }.contains(m.kind));
    expect(milestones, hasLength(5));
  });

  test('markers and nodes share one timeline inside a month', () {
    final rows = seasonRows(
      nodes: const [],
      today: DateTime.utc(2026, 9, 16),
      optionsFor: (_) => 0,
      markers: seasonMarkers(_facts()),
    );
    // May holds two markers, in date order: last frost the 13th, ijsheiligen
    // the 11th, so ijsheiligen comes first.
    final may = rows
        .skipWhile((r) => !(r.kind == SeasonRowKind.month && r.month == 5))
        .skip(1)
        .takeWhile((r) => r.kind == SeasonRowKind.marker)
        .map((r) => r.marker!.kind)
        .toList();
    expect(may, [SeasonMarkerKind.ijsheiligen, SeasonMarkerKind.lastFrost]);
  });
}
