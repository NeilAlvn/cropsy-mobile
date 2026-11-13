import 'package:cropsy/features/grow/planting_calendar_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calendarFrac wraps into the next season instead of clamping', () {
    final start = DateTime(2026, 1, 1);
    expect(calendarFrac(DateTime(2026, 1, 1), start), 0);
    // Garlic: planted Oct, harvested Jul next year -> end < start, so it wraps.
    final plant = calendarFrac(DateTime(2026, 10, 15), start);
    final harvest = calendarFrac(DateTime(2027, 7, 1), start);
    expect(harvest, lessThan(plant));
    expect(harvest, greaterThan(0.4));
  });
}
