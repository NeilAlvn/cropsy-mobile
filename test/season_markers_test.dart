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
    );

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
