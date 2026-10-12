/// Free-tier gates that sit in front of an action rather than a screen.
///
/// Planning plants (no plantedOn) are always free and unlimited; only plants
/// actually growing count against the free limit.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../timing/dates.dart';
import '../paywall/paywall_screen.dart';
import '../repository_scope.dart';

/// Free gardens grow this many plants at once.
const freeGrowingPlants = 3;

/// Whether starting one more plant needs premium.
bool overPlantLimit(int growing, {required bool premium, int limit = freeGrowingPlants}) =>
    !premium && growing >= limit;

/// The home upsell shows at most once per seven days. [shownOn] is the ISO day
/// it last appeared, null if never.
bool homeCardDue(String? shownOn, String today) =>
    shownOn == null || parseIso(today).difference(parseIso(shownOn)).inDays >= 7;

/// Call before a plant starts growing. True when there is room (or the person
/// just bought it); otherwise says plainly why nothing happened.
Future<bool> roomToGrow(BuildContext context) async {
  final repo = RepositoryScope.of(context);
  final purchases = PurchaseScope.maybeOf(context);
  final limit = purchases?.maxGrowingPlants ?? freeGrowingPlants;
  final growing = (await repo.growingPlants()).length;
  if (!overPlantLimit(growing, premium: purchases?.premium ?? false, limit: limit)) return true;
  if (!context.mounted) return false;
  final bought = await Navigator.of(context).push<bool>(MaterialPageRoute(
    builder: (_) => const PaywallScreen(trigger: PaywallTrigger.plantLimit),
    fullscreenDialog: true,
  ));
  if (bought == true) return true;
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Str.freePlantLimit(limit).of(context))));
  }
  return false;
}
