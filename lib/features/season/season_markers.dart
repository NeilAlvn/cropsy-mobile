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

  /// The first thing the gardener actually put in the ground this year.
  firstSow,

  /// The 1st, 10th, 25th, 50th or 100th harvest they logged this year.
  harvest,

  /// A run of days kept going: a week, a month, a hundred days.
  streak,

  /// A plant photographed this month that also has an older picture.
  photoCompare,
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
  /// crop slug for the checklist, companion, first-sowing and harvest stops, a
  /// collection slug for the collection stop, a plant id for the photo stop —
  /// its two pictures live on that plant, not on the crop. Null on the markers
  /// that only have a story to tell.
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
///
/// The milestone stops — what the gardener actually did — are capped the same
/// way, and harder, because a good year produces them by the dozen: the first
/// sowing happens once, the two most recent harvest milestones stand for all of
/// them, the newest streak run stands for the ones before it, and one plant is
/// worth photographing beside its younger self. Five stops in a whole year, and
/// a first-time gardener with no history gets none of them. A trophy that is
/// always there is wallpaper; the year should read as a story with a handful of
/// good days in it, not as a cabinet.
const _checklistPerMonth = 2;
const _companionsPerSeason = 2;
const _harvestMilestonesPerSeason = 2;
const _streakMilestonesPerSeason = 1;

/// Where the harvest count earns a stop. Early enough that a first harvest is
/// celebrated, spaced widely enough that a productive July is not a parade.
const _harvestMilestones = [1, 10, 25, 50, 100];

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
    this.firstSow,
    this.harvests = const [],
    this.streaks = const [],
    this.photos = const [],
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

  // ── what the gardener has already done ───────────────────────────────────
  //
  // All four are history, handed over as plain dated records. The builder never
  // asks the database anything; it only decides which of these are worth a stop
  // and where they sit.

  /// The earliest sow the gardener logged, and the crop it was. Null until the
  /// first one goes in — which is most of January.
  final ({String slug, String on})? firstSow;

  /// Every harvest logged, with the day it was logged on. The builder counts
  /// them in date order itself, so the caller may hand them over in any.
  final List<({String slug, String on})> harvests;

  /// Streak runs that reached a milestone, with the day they reached it. Dated
  /// by `streakMilestones` in timing/streak.dart, so a stop here and the count
  /// on Home come from the same freeze rules.
  final List<({int days, String on})> streaks;

  /// Per plant, the first and last day it was photographed this year. Two dates
  /// are all a "look how far it has come" needs: the gap between them is the
  /// story, and the plant id is what opens the pictures.
  final List<({String plantId, String firstOn, String lastOn})> photos;
}

/// A crop's name, falling back to its slug.
///
/// The companion stop drops a crop the catalogue does not know, because it is
/// suggesting something new and there is nothing to suggest. A milestone is the
/// gardener's own record: a harvest they logged does not stop having happened
/// because the catalogue lost the slug, so it prints the slug the way every
/// other screen does rather than vanishing.
LocalizedText _name(MarkerFacts facts, String slug) =>
    facts.nameOf(slug) ?? LocalizedText(nl: slug, en: slug);

/// The last [n] of a list, or all of it. Both milestone caps are "the most
/// recent ones", and the list is already in date order by the time they apply.
List<T> _lastOf<T>(List<T> xs, int n) =>
    xs.length <= n ? xs : xs.sublist(xs.length - n);

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

  // ── what the gardener has already done ─────────────────────────────────────
  //
  // History, and history starts on New Year's Day: the path tells one year's
  // story, so last season's first sowing and last season's streak belong to
  // last season's path.
  bool thisYear(String iso) => iso.startsWith('$year-');

  // Where the season actually began. The date is the day it was logged rather
  // than the day it was planned for, because that is the day it happened.
  final sow = facts.firstSow;
  if (sow != null && thisYear(sow.on)) {
    out.add(SeasonMarker(
      kind: SeasonMarkerKind.firstSow,
      on: sow.on,
      title: Str.pathFirstSow,
      caption: Str.pathFirstSowCaption(_name(facts, sow.slug)),
      slug: sow.slug,
    ));
  }

  // Harvests, numbered in the order they were picked. Only the two most recent
  // milestones stand: a hundred-harvest year would otherwise hang five trophies
  // on the path, and the early ones are the ones the gardener has moved past.
  final picked = [
    for (final h in facts.harvests)
      if (thisYear(h.on)) h
  ]..sort((a, b) => a.on.compareTo(b.on));
  final trophies = <SeasonMarker>[];
  for (var i = 0; i < picked.length; i++) {
    final n = i + 1;
    if (!_harvestMilestones.contains(n)) continue;
    trophies.add(SeasonMarker(
      kind: SeasonMarkerKind.harvest,
      on: picked[i].on,
      title: Str.pathHarvest(n),
      caption: Str.pathHarvestCaption(_name(facts, picked[i].slug)),
      slug: picked[i].slug,
    ));
  }
  out.addAll(_lastOf(trophies, _harvestMilestonesPerSeason));

  // The run they are proudest of is the longest one they reached, and it says
  // everything the shorter ones did. Seven, thirty and a hundred days all on
  // the path is the same sentence three times.
  final runs = [
    for (final s in facts.streaks)
      if (thisYear(s.on)) s
  ];
  for (final run in _lastOf(runs, _streakMilestonesPerSeason)) {
    out.add(SeasonMarker(
      kind: SeasonMarkerKind.streak,
      on: run.on,
      title: Str.pathStreak(run.days),
      caption: Str.pathStreakCaption,
    ));
  }

  // One plant photographed this month that also has an older picture of itself.
  // The widest gap wins: the plant that changed most is the one worth opening,
  // and a second invitation to look at pictures is not a second story.
  ({String plantId, String firstOn, String lastOn})? best;
  var widest = 0;
  for (final plant in facts.photos) {
    if (!thisYear(plant.firstOn) || !thisYear(plant.lastOn)) continue;
    final first = parseIso(plant.firstOn);
    final last = parseIso(plant.lastOn);
    // "This month" and "an earlier month", both of this year — two pictures
    // from the same month are the same plant on the same day, near enough.
    if (last.month != facts.today.month || first.month >= last.month) continue;
    final gap = last.difference(first).inDays;
    if (gap <= widest) continue;
    widest = gap;
    best = plant;
  }
  if (best != null) {
    out.add(SeasonMarker(
      kind: SeasonMarkerKind.photoCompare,
      on: best.lastOn,
      title: Str.pathPhotoCompare,
      caption: Str.pathPhotoCompareCaption(Str.month(parseIso(best.firstOn).month)),
      slug: best.plantId,
    ));
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
