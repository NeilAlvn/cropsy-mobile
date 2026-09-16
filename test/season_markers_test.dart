import 'package:cropsy/features/season/season_markers.dart';
import 'package:cropsy/features/season/season_rows.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

MarkerFacts _facts({
  int plants = 3,
  bool photo = false,
  double euros = 0,
  String? weather,
}) =>
    MarkerFacts(
      today: DateTime.utc(2026, 9, 16),
      frost: const FrostProfile(lastFrost: '2026-05-13', firstFrost: '2026-10-15'),
      plantCount: plants,
      photoThisMonth: photo,
      euros: euros,
      kilos: 0,
      weatherTitle: weather,
      weatherCaption: weather == null ? null : 'because reasons',
    );

Set<SeasonMarkerKind> _kinds(List<SeasonMarker> m) => m.map((e) => e.kind).toSet();

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
    expect(marks.firstWhere((m) => m.kind == SeasonMarkerKind.payoff).caption,
        contains('€24'));
  });

  test('a weather change lands on today', () {
    final marks = seasonMarkers(_facts(weather: 'Rain did the watering'));
    final weather = marks.firstWhere((m) => m.kind == SeasonMarkerKind.weather);
    expect(weather.on, '2026-09-16');
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
