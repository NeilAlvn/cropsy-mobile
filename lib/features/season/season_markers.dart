/// The things on the season path that are not a plant's own task.
///
/// Frost dates, the seed order, the monthly photo, the payoff, the recap and
/// whatever the weather changed today. All of it derives from the frost profile
/// and a handful of counts, so it is a pure function and gets tested as one.
library;

import '../../l10n/strings.dart';
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
}

class SeasonMarker {
  const SeasonMarker({
    required this.kind,
    required this.on,
    required this.title,
    required this.caption,
  });

  final SeasonMarkerKind kind;

  /// ISO date the marker sits on.
  final String on;
  final LocalizedText title;
  final LocalizedText caption;
}

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
