/// The things on the season path that are not a plant's own task.
///
/// Frost dates, the seed order, the monthly photo, the payoff, the recap,
/// whatever the weather changed today, and the three stops that come from
/// content the app already carries: the month's checklist job, a good
/// neighbour for a crop already on the path, and a themed list for a thin
/// month. All of it derives from the frost profile, a handful of counts and
/// plain data handed in, so it is a pure function and gets tested as one.
library;

import '../../data/companions.dart';
import '../../l10n/strings.dart';
import '../../timing/content_snapshot.dart';
import '../../timing/dates.dart';
import '../../timing/types.dart';

enum SeasonMarkerKind {
  ijsheiligen,
  lastFrost,
  firstFrost,
  orderSeeds,
  photo,
  payoff,
  recap,
  weather,

  /// The month's editorial job from the content snapshot — the same list Home
  /// shows, on the path where the month actually is.
  checklist,

  /// A good neighbour for a crop the gardener already has, which they do not.
  companion,

  /// A themed list of crops, parked in a month that has little else.
  collection,
}

class SeasonMarker {
  const SeasonMarker({
    required this.kind,
    required this.on,
    required this.title,
    required this.caption,
    this.slug,
  });

  final SeasonMarkerKind kind;

  /// ISO date the marker sits on.
  final String on;
  final LocalizedText title;
  final LocalizedText caption;

  /// What the stop is about, when it is about something the app can open: a
  /// crop slug for the checklist and companion stops, a collection slug for the
  /// collection stop. Null on the markers that only have a story to tell.
  final String? slug;
}

/// The cap, stated once.
///
/// The path is a story, not a feed. The content the app carries is generous —
/// several checklist jobs a month, a dozen-odd companion pairs — and pouring
/// all of it onto the snake would bury the gardener's own sowings. So every new
/// kind has a hard ceiling: at most two checklist stops in any one month, two
/// companion stops in the whole year, and exactly one collection stop. An empty
/// month that gains six stops is worse than the dead end it replaced.
const _checklistPerMonth = 2;
const _companionsPerSeason = 2;

/// The default name lookup: knows nothing, so the companion stops stay away.
LocalizedText? _noName(String _) => null;

/// What the app knows when it builds the markers. Primitives only: the builder
/// never touches the database, so a test can state a whole season in one line.
class MarkerFacts {
  const MarkerFacts({
    required this.today,
    required this.frost,
    required this.plantCount,
    required this.photoThisMonth,
    required this.euros,
    required this.kilos,
    this.weatherTitle,
    this.weatherCaption,
    this.checklist = const [],
    this.grown = const [],
    this.collections = const [],
    this.busyMonths = const {},
    this.nameOf = _noName,
  });

  final DateTime today;
  final FrostProfile frost;

  /// Plants in the garden. With none of them, the path has nothing to say about
  /// seed orders or photos, so those markers stay away.
  final int plantCount;
  final bool photoThisMonth;
  final double euros;
  final double kilos;

  /// Today's weather change, if the engine made one.
  final LocalizedText? weatherTitle;
  final LocalizedText? weatherCaption;

  /// The whole year's editorial checklist from the content snapshot. Each item
  /// carries its own month, so the builder needs nothing else to place it.
  final List<ChecklistItem> checklist;

  /// The crops on the path, each with the date its own first step sits on, so a
  /// companion suggestion can land beside the crop it is about.
  final List<({String slug, String on})> grown;

  /// Themed lists to point at. The screen decides which source has content —
  /// the snapshot's editorial sets or the ones derived from the catalogue — and
  /// hands over the winner, because that choice is not a season question.
  final List<({String slug, LocalizedText title, bool draft})> collections;

  /// Months that already hold a plant's own node or step. The collection stop
  /// keeps out of these: they have their own story to tell.
  final Set<int> busyMonths;

  /// A crop's names, or null when the catalogue does not have that slug. A
  /// function rather than a map because the builder cannot know in advance
  /// which partner slugs it will end up asking about — and `seasonRows` already
  /// takes its month counts the same way.
  final LocalizedText? Function(String slug) nameOf;
}

String _iso(int year, int month, int day) =>
    '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

List<SeasonMarker> seasonMarkers(MarkerFacts facts) {
  final year = facts.today.year;
  final out = <SeasonMarker>[
    // The Dutch gardener's calendar turns on this week, not on the average
    // frost date, so it is a first-class marker (PRD §4).
    SeasonMarker(
      kind: SeasonMarkerKind.ijsheiligen,
      on: _iso(year, 5, 11),
      title: Str.ijsheiligen,
      caption: Str.ijsheiligenSub,
    ),
    SeasonMarker(
      kind: SeasonMarkerKind.lastFrost,
      on: facts.frost.lastFrost,
      title: Str.lastFrost,
      caption: Str.lastFrostSub,
    ),
    SeasonMarker(
      kind: SeasonMarkerKind.firstFrost,
      on: facts.frost.firstFrost,
      title: Str.firstFrost,
      caption: Str.firstFrostSub,
    ),
    SeasonMarker(
      kind: SeasonMarkerKind.recap,
      on: _iso(year, 12, 20),
      title: Str.recapTitle(year),
      caption: facts.euros > 0
          ? Str.recapPicked(facts.euros.round())
          : Str.recapSub,
    ),
  ];

  if (facts.plantCount > 0) {
    // Seed goes on sale in the quiet months, which is exactly when the app is
    // otherwise silent. This is the off-season reason to open it.
    out.add(SeasonMarker(
      kind: SeasonMarkerKind.orderSeeds,
      on: _iso(year, 1, 10),
      title: Str.orderSeed,
      caption: Str.cropsOnList(facts.plantCount),
    ));

    if (!facts.photoThisMonth) {
      out.add(SeasonMarker(
        kind: SeasonMarkerKind.photo,
        on: _iso(year, facts.today.month, 15),
        title: Str.monthPhoto,
        caption: Str.seasonInPictures,
      ));
    }

    out.add(SeasonMarker(
      kind: SeasonMarkerKind.payoff,
      on: facts.frost.firstFrost,
      title: Str.seasonTally,
      caption: facts.euros > 0 || facts.kilos > 0
          ? Str.tallySoFar(facts.euros.round(), facts.kilos.toStringAsFixed(1))
          : Str.tallyEmpty,
    ));
  }

  // The month's jobs, from the same checklist Home renders.
  //
  // Draft rows are unverified beta content. Everywhere else they ship with a
  // visible "concept" badge (PRD §4.3); a path stop is a badge and a line of
  // type with no room for a second label, so rather than show them unmarked the
  // path leaves them to the screens that can say what they are.
  final perMonth = <int, int>{};
  for (final item in facts.checklist) {
    if (item.draft || item.month < 1 || item.month > 12) continue;
    final taken = perMonth[item.month] ?? 0;
    if (taken >= _checklistPerMonth) continue;
    perMonth[item.month] = taken + 1;
    out.add(SeasonMarker(
      kind: SeasonMarkerKind.checklist,
      // The first days of the month: a job belongs at the head of its section,
      // and the running count keeps the snapshot's own order through the sort.
      on: _iso(year, item.month, taken + 1),
      title: item.title,
      caption: Str.pathChecklistCaption,
      slug: item.link,
    ));
  }

  // Good neighbours. One partner per crop and two in the year: a gardener with
  // six crops would otherwise get a wall of pairings instead of a season.
  final growing = {for (final crop in facts.grown) crop.slug};
  final suggested = <String>{};
  for (final crop in [...facts.grown]..sort((a, b) => a.on.compareTo(b.on))) {
    if (suggested.length >= _companionsPerSeason) break;
    // A sowing that has been and gone cannot be companion-planted any more.
    if (parseIso(crop.on).isBefore(facts.today)) continue;
    final have = facts.nameOf(crop.slug);
    if (have == null) continue;
    for (final partner in companionsOf(crop.slug)) {
      if (growing.contains(partner) || suggested.contains(partner)) continue;
      final name = facts.nameOf(partner);
      // Not in the catalogue means nothing to open and no name to print.
      if (name == null) continue;
      suggested.add(partner);
      out.add(SeasonMarker(
        kind: SeasonMarkerKind.companion,
        on: crop.on,
        title: Str.pathCompanion(name),
        caption: Str.pathCompanionCaption(have),
        slug: partner,
      ));
      break;
    }
  }

  // One themed list, in a month that has little of its own to say.
  //
  // "Quiet" here means: no plant of the gardener's, but something of the
  // season's already on it. That second half matters — a month with nothing at
  // all is the one `seasonRows` fills with the "still sowable" chest, and the
  // chest is the better offer. This stop thickens a thin month; it never
  // displaces a chest.
  final lists = facts.collections.where((c) => !c.draft).toList();
  if (lists.isNotEmpty) {
    final marked = {for (final m in out) parseIso(m.on).month};
    for (var month = facts.today.month; month <= 12; month++) {
      if (facts.busyMonths.contains(month) || !marked.contains(month)) continue;
      out.add(SeasonMarker(
        kind: SeasonMarkerKind.collection,
        on: _iso(year, month, 15),
        title: lists.first.title,
        caption: Str.pathCollectionCaption,
        slug: lists.first.slug,
      ));
      break;
    }
  }

  final weather = facts.weatherTitle;
  if (weather != null) {
    out.add(SeasonMarker(
      kind: SeasonMarkerKind.weather,
      on: toIso(facts.today),
      title: weather,
      caption: facts.weatherCaption ??
          const LocalizedText(
            nl: 'Het weer heeft een taak verzet',
            en: 'The weather moved a task',
          ),
    ));
  }

  out.sort((a, b) => a.on.compareTo(b.on));
  return out;
}
