import 'package:cropsy/data/frost_presets.dart';
import 'package:cropsy/data/seed.dart';
import 'package:cropsy/db/database.dart';
import 'package:cropsy/features/garden/garden_repository.dart';
import 'package:cropsy/features/location/frost_lookup.dart';
import 'package:cropsy/features/location/saved_location.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const melbourne = FrostLookup(
    profile: FrostProfile(lastFrost: '2026-09-20', firstFrost: '2027-05-05', south: true),
    lat: -37.8,
    lon: 145.0,
    source: 'open-meteo',
  );

  test('encode / decode round trip', () {
    const l = SavedLocation(
      name: 'Melbourne, Victoria',
      profile: FrostProfile(lastFrost: '2026-09-20', firstFrost: '2027-05-05', south: true, regime: 'frost'),
      source: 'open-meteo',
      country: 'AU',
      lat: -37.8,
      lon: 145.0,
    );
    final back = SavedLocation.decode(l.encode())!;
    expect(back.name, 'Melbourne, Victoria');
    expect(back.profile.south, isTrue);
    expect(back.country, 'AU');
    expect(SavedLocation.decode('not json'), isNull);
    expect(SavedLocation.decode(null), isNull);
  });

  test('presets only for NL, BE or an unknown country', () {
    expect(usesNlBePresets('NL'), isTrue);
    expect(usesNlBePresets('BE'), isTrue);
    expect(usesNlBePresets(null), isTrue);
    expect(usesNlBePresets('US'), isFalse);
    expect(usesNlBePresets('GB'), isFalse);
  });

  test('a looked-up location survives a restart', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final first = await GardenRepository.create(db: db, today: demoToday, observations: (_, _) async => null);
    await first.createGarden(region: defaultRegion, kind: GardenKind.garden);
    await first.setLocation(name: 'Melbourne, Victoria', lookup: melbourne, country: 'AU');

    final second = await GardenRepository.create(db: db, today: '2028-03-01', observations: (_, _) async => null);
    expect(second.regionName, 'Melbourne, Victoria');
    expect(second.country, 'AU');
    expect(second.frostSource, 'open-meteo');
    expect(second.frost.lastFrost, '2027-09-20');
    expect(second.frost.firstFrost, '2028-05-05');
  });

  test('frostSource is whatever the lookup said', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = await GardenRepository.create(db: db, today: demoToday, observations: (_, _) async => null);
    const preset = FrostLookup(
      profile: FrostProfile(lastFrost: '2026-04-15', firstFrost: '2026-11-01'),
      lat: 52.0,
      lon: 5.0,
      source: 'preset',
    );
    await repo.setLocation(name: 'Utrecht', lookup: preset, country: 'NL');
    expect(repo.frostSource, 'preset');
  });

  test('onboarding with a lookup names the garden after the place, not Randstad', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = await GardenRepository.create(db: db, today: demoToday, observations: (_, _) async => null);
    await repo.createGarden(region: defaultRegion, kind: GardenKind.garden, lookup: melbourne, placeName: 'Melbourne, Victoria', country: 'AU');
    expect(repo.regionName, 'Melbourne, Victoria');
    expect(repo.frost.south, isTrue);
  });

  const lookup = FrostLookup(
    profile: FrostProfile(lastFrost: '2026-04-15', firstFrost: '2026-11-01'),
    lat: 53.2,
    lon: 6.5,
    source: 'open-meteo',
  );

  test('1.0.1 upgrade: a garden at a preset coordinate recovers that preset', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final groningen = frostRegions.firstWhere((r) => r.name.contains('Groningen'));
    final first = await GardenRepository.create(db: db, today: demoToday, observations: (_, _) async => null);
    await first.createGarden(region: groningen, kind: GardenKind.garden);
    // 1.0.1 never wrote location.v1.
    await (db.delete(db.appMeta)..where((t) => t.key.equals(SavedLocation.metaKey))).go();

    final second = await GardenRepository.create(db: db, today: demoToday, observations: (_, _) async => null);
    await pumpEventQueue();
    expect(second.regionName, groningen.name);
    expect(second.country, 'NL');
    expect(SavedLocation.decode(await second.meta(SavedLocation.metaKey)), isNotNull);
  });

  test('a postcode lookup stores NL', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = await GardenRepository.create(db: db, today: demoToday, observations: (_, _) async => null);
    await repo.createGarden(region: defaultRegion, kind: GardenKind.garden, lookup: lookup, postcode: '9711AA');
    expect(repo.country, 'NL');
    await repo.setLocation(name: '9711AA', lookup: lookup, postcode: '9711AA');
    expect(repo.country, 'NL');
  });

  test('needsClimate: looked-up places without a climate curve only', () {
    const base = FrostProfile(lastFrost: '2026-02-18', firstFrost: '2026-12-08');
    expect(needsClimate(const SavedLocation(name: 'Austin', profile: base, source: 'open-meteo', lat: 30.3, lon: -97.7)), isTrue);
    expect(needsClimate(const SavedLocation(name: 'Randstad', profile: base, source: 'preset', lat: 52.3, lon: 4.9)), isFalse);
    expect(needsClimate(const SavedLocation(name: 'X', profile: base, source: 'open-meteo')), isFalse);
    final withClimate = FrostProfile(lastFrost: '2026-02-18', firstFrost: '2026-12-08', weeklyTmax: List.filled(52, 20.0));
    expect(needsClimate(SavedLocation(name: 'Austin', profile: withClimate, source: 'open-meteo', lat: 30.3, lon: -97.7)), isFalse);
  });
}
