import 'package:cropsy/l10n/date_fmt.dart';
import 'package:cropsy/l10n/region.dart';
import 'package:cropsy/timing/content_snapshot.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Map<String, dynamic> _item(String anchor, int from, int to, String en) => {
      'anchor': anchor,
      'from_weeks': from,
      'to_weeks': to,
      'title': {'nl': en, 'en': en},
      'body': {'nl': en, 'en': en},
      'link': null,
    };

void main() {
  setUpAll(() => initializeDateFormatting());
  tearDown(() => AppRegion.apply(lang: 'nl', country: 'NL'));

  final snap = ContentSnapshot.fromJson({
    'version': 't',
    'frost_checklist': [
      _item('last_frost', -12, -7, 'order seeds'),
      _item('last_frost', -2, 0, 'harden off'),
      _item('first_frost', -5, -1, 'bring pots in'),
      _item('first_frost', 0, 8, 'plant garlic'),
    ],
  });
  String titles(FrostProfile f, String today) =>
      snap.frostChecklistFor(f, today).map((c) => c.title.en).join(',');

  test('items follow the frost dates, not the calendar month', () {
    const chicago = FrostProfile(lastFrost: '2026-04-22', firstFrost: '2026-11-08');
    expect(titles(chicago, '2026-11-14'), 'plant garlic');
    expect(titles(chicago, '2026-10-20'), 'bring pots in');
    // Next spring's window, computed from this season's profile.
    expect(titles(chicago, '2027-02-10'), 'order seeds');
    expect(titles(chicago, '2026-04-15'), 'harden off');
    // No gap between "week -1" and "week 0": Leeds, 3 days before first frost.
    const leeds = FrostProfile(lastFrost: '2026-04-27', firstFrost: '2026-11-17');
    expect(titles(leeds, '2026-11-14'), 'bring pots in');
  });

  test('southern hemisphere: November is spring', () {
    const melbourne = FrostProfile(lastFrost: '2026-07-29', firstFrost: '2027-06-30', south: true);
    expect(titles(melbourne, '2026-07-20'), contains('harden off'));
    expect(titles(melbourne, '2026-11-14'), '');
  });

  test('season path: items placed at their window start in this season', () {
    const melbourne = FrostProfile(lastFrost: '2026-07-29', firstFrost: '2027-06-30', south: true);
    final placed = {for (final c in snap.frostChecklistDated(melbourne)) c.title.en: c.on};
    expect(placed['order seeds'], '2027-05-06'); // before the Jul start: next spring's prep
    expect(placed['harden off'], '2026-07-15');
    expect(placed['plant garlic'], '2027-06-30');
    const auckland = FrostProfile(lastFrost: '2026-09-04', firstFrost: '2027-06-30', south: true, regime: 'frost_free');
    expect(snap.frostChecklistDated(auckland), isEmpty);
  });

  test('frost-free places get no frost checklist', () {
    const auckland = FrostProfile(lastFrost: '2026-09-04', firstFrost: '2027-06-30', south: true, regime: 'frost_free');
    expect(titles(auckland, '2026-08-30'), '');
  });

  test('engine ISO dates are shown as day/month', () {
    AppRegion.apply(lang: 'en', country: 'US');
    expect(localDates('close to first frost (2026-11-08).'), 'close to first frost (Nov 8).');
    AppRegion.apply(lang: 'en', country: 'GB');
    expect(localDates('(2026-11-08)'), '(8 Nov)');
  });
}
