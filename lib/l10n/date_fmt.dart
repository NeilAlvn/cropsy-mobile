/// Dates. English uses locale skeletons, so `AppRegion`'s intl locale decides
/// the order (en_US "May 3", en_GB "3 May"). Other languages keep their
/// fixed patterns, exactly as before.
library;

import 'package:intl/intl.dart';

import '../timing/dates.dart';
import '../timing/season_year.dart';

bool get _en => (Intl.defaultLocale ?? 'en').startsWith('en');
bool get _us => Intl.defaultLocale == 'en_US';
// Non-US English keeps the bare 'en' names ("Sep", not en_GB's "Sept").
String? get _nameLocale => _en ? 'en' : null;

String dayMonth(DateTime d) => (_us ? DateFormat.MMMd() : DateFormat('d MMM', _nameLocale)).format(d);
String dayMonthIso(String iso) => dayMonth(parseIso(iso));

/// Engine text (replan warnings) carries ISO dates so it stays identical to the
/// backend; show them as the user's day/month.
String localDates(String s) => s.replaceAllMapped(RegExp(r'\b\d{4}-\d{2}-\d{2}\b'), (m) => dayMonthIso(m[0]!));
String weekdayDayMonth(DateTime d) =>
    (_us ? DateFormat('EEEE').add_MMMd() : DateFormat('EEEE d MMM', _nameLocale)).format(d);
String dayMonthYear(DateTime d) =>
    (_us ? DateFormat.yMMMd() : DateFormat('d MMM yyyy', _nameLocale)).format(d);
String weekdayShort(DateTime d) => (_en ? DateFormat.E() : DateFormat('EEE')).format(d);
String monthShort(int month) => DateFormat('MMM', _nameLocale).format(DateTime(2000, month));
String clock(DateTime d) => DateFormat.jm().format(d);

/// "2026" in the north; "2026/27" in the south, where the season runs Jul–Jun.
String seasonLabel(String todayIso, {required bool south}) {
  final y = seasonYearOf(todayIso, south: south);
  return south ? '$y/${((y + 1) % 100).toString().padLeft(2, '0')}' : '$y';
}
