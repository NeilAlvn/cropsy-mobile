/// Dates on locale skeletons, so `AppRegion`'s intl locale decides the order
/// (en_US "May 3", en_GB "3 May", nl "3 mei").
library;

import 'package:intl/intl.dart';

import '../timing/dates.dart';
import '../timing/season_year.dart';

String dayMonth(DateTime d) => DateFormat.MMMd().format(d);
String dayMonthIso(String iso) => dayMonth(parseIso(iso));
String weekdayDayMonth(DateTime d) => DateFormat('EEEE').add_MMMd().format(d);
String dayMonthYear(DateTime d) => DateFormat.yMMMd().format(d);
String weekdayShort(DateTime d) => DateFormat.E().format(d);
String monthShort(int month) => DateFormat.MMM().format(DateTime(2000, month));
String clock(DateTime d) => DateFormat.jm().format(d);

/// "2026" in the north; "2026/27" in the south, where the season runs Jul–Jun.
String seasonLabel(String todayIso, {required bool south}) {
  final y = seasonYearOf(todayIso, south: south);
  return south ? '$y/${((y + 1) % 100).toString().padLeft(2, '0')}' : '$y';
}
