/// Bundled frost presets for onboarding (F3). In the real app the frost profile
/// comes from `GET /api/frost?lat=&lon=` with a bundled national default offline
/// (API contract §3). For the prototype we skip the network and let the user
/// pick a region, each mapped to a representative NL/BE frost profile.
library;

import '../timing/types.dart';

class FrostRegion {
  const FrostRegion(this.name, this.profile);
  final String name;
  final FrostProfile profile;
}

/// Coarse but plausible; enough to make the "why" in crop detail read true.
const frostRegions = <FrostRegion>[
  FrostRegion('Randstad (Amsterdam/Utrecht)',
      FrostProfile(lastFrost: '2026-04-15', firstFrost: '2026-11-01')),
  FrostRegion('Coastal (Den Haag/Rotterdam)',
      FrostProfile(lastFrost: '2026-04-08', firstFrost: '2026-11-12')),
  FrostRegion('South (Maastricht/Limburg)',
      FrostProfile(lastFrost: '2026-04-20', firstFrost: '2026-10-28')),
  FrostRegion('North-east (Groningen/Twente)',
      FrostProfile(lastFrost: '2026-04-28', firstFrost: '2026-10-22')),
  FrostRegion('Belgium (Antwerp/Brussels)',
      FrostProfile(lastFrost: '2026-04-12', firstFrost: '2026-11-05')),
];

const defaultRegion = FrostRegion(
    'Randstad (Amsterdam/Utrecht)',
    FrostProfile(lastFrost: '2026-04-15', firstFrost: '2026-11-01'));
