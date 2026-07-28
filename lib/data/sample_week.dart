/// Prototype-only sample forecast. The real app calls
/// `POST /api/schedule/weather-adjust` with live weather; here we synthesise a
/// plausible two-week forecast around "today" so the weather-aware hints (F4)
/// render — a wet spell (→ skip) and a hot dry spell (→ water earlier). Replace
/// with the live weather layer when sync/network lands.
library;

import '../timing/dates.dart';
import '../timing/weather_adjust.dart';

/// A scripted 18-day pattern of (precip_mm, temp_min, temp_max), starting three
/// days before `today`. Front-loaded rain, then a warm-up into a hot dry spell.
const _pattern = <List<num>>[
  [0, 9, 16], // today-3
  [2, 9, 15],
  [9, 8, 14], // wet
  [8, 8, 13], // wet  → a watering due around here gets "skip"
  [1, 9, 16],
  [0, 11, 20],
  [0, 13, 24],
  [0, 15, 28],
  [0, 17, 32], // hot
  [0, 18, 34], // hot dry → a watering due after here gets "water earlier"
  [0, 17, 30],
  [3, 15, 25],
  [0, 14, 23],
  [0, 13, 22],
  [0, 12, 21],
  [0, 12, 20],
  [1, 11, 19],
  [0, 11, 18],
];

List<DayObservation> sampleObservations(String todayIso) {
  final start = addDays(parseIso(todayIso), -3);
  return [
    for (var i = 0; i < _pattern.length; i++)
      DayObservation(
        date: toIso(addDays(start, i)),
        precipMm: _pattern[i][0],
        tempMinC: _pattern[i][1],
        tempMaxC: _pattern[i][2],
      ),
  ];
}
