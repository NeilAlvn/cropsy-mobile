/// Display units. Data stays metric (°C, mm, cm, L, kg, m²); these turn a
/// metric value into the text a user in [AppRegion] expects. Imperial for the
/// US only.
library;

import 'package:intl/intl.dart';

import 'region.dart';

String _n(num v, {int decimals = 0, bool upToOne = false}) {
  if (upToOne) {
    return NumberFormat('#,##0.#', Intl.defaultLocale).format(v.abs() < 0.05 ? 0 : v);
  }
  if (decimals == 0) v = v.round(); // half away from zero, as the old code
  // Values that round to zero print as 0, never "-0".
  final x = v.abs() <= (decimals == 0 ? 0.5 : 0.05) ? 0 : v;
  return NumberFormat(decimals == 0 ? '#,##0' : '#,##0.${'#' * decimals}', Intl.defaultLocale).format(x);
}

bool get _imp => AppRegion.imperial;

/// [exact]: metric keeps one decimal (soil gates like 8.5). [spaced]: always put
/// a space before the unit. de/fr/sv/pt always do, as their old templates did.
String tempC(num c, {bool exact = false, bool spaced = false}) {
  final sp = spaced || const ['de', 'fr', 'sv', 'pt'].contains((Intl.defaultLocale ?? '').split('_').first) ? ' ' : '';
  return _imp ? '${_n(c * 9 / 5 + 32)}$sp°F' : '${_n(c, upToOne: exact)}$sp°C';
}
String tempBare(num c) => _imp ? '${_n(c * 9 / 5 + 32)}°' : '${_n(c)}°';
String rainMm(num mm) => _imp ? '${_n(mm / 25.4, decimals: 1)} in' : '${_n(mm, decimals: 1)} mm';
String lengthCm(num cm) => _imp ? '${_n(cm / 2.54)} in' : '${_n(cm)} cm';
String depthMm(num mm) => _imp ? '${_n(mm / 25.4, decimals: 1)} in' : '${_n(mm)} mm';
String volumeL(num l) => _imp ? '${_n(l / 3.785, decimals: 1)} gal' : '${_n(l)} L';
String massKg(num kg) => _imp ? '${_n(kg * 2.20462, decimals: 1)} lb' : '${_n(kg, decimals: 1)} kg';
String areaM2(num m2) => _imp ? '${_n(m2 * 10.7639)} sq ft' : '${_n(m2)} m²';
String distanceKm(num km) => _imp ? '${_n(km * 0.621371, decimals: 1)} mi' : '${_n(km)} km';

/// Input: the unit a user types in, and conversion to/from the stored metric value.
String get massUnit => _imp ? 'lb' : 'kg';
String get volumeUnit => _imp ? 'gal' : 'L';
double kgFromInput(double v) => _imp ? v / 2.20462 : v;
double litresFromInput(double v) => _imp ? v * 3.785 : v;
double inputFromKg(double kg) => _imp ? kg * 2.20462 : kg;
double inputFromLitres(double l) => _imp ? l / 3.785 : l;
