/// Season-year helpers. North: the season is the calendar year. South: it runs
/// 1 Jul – 30 Jun, so a southern autumn date (Jan–Jun) belongs to season + 1.
/// Direct port of `seasonYearOf` / `isoForSeason` in the backend's
/// `src/weather/frost-analysis.ts`.
library;

int seasonYearOf(String iso, {required bool south}) {
  final y = int.parse(iso.substring(0, 4));
  final m = int.parse(iso.substring(5, 7));
  return south && m < 7 ? y - 1 : y;
}

String isoForSeason(String mmdd, int season, {required bool south}) {
  final m = int.parse(mmdd.substring(0, 2));
  return '${south && m < 7 ? season + 1 : season}-$mmdd';
}

DateTime seasonStart(int season, {required bool south}) =>
    DateTime.utc(season, south ? 7 : 1, 1);

/// Calendar month (1-12) shown in column [i] (0-11) of a season axis.
int monthAt(int i, {required bool south}) => ((south ? 6 : 0) + i) % 12 + 1;
