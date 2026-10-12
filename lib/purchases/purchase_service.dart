/// Purchases via RevenueCat. Trial-first: yearly with a free week is the plan
/// the paywall leads with; monthly and lifetime sit beside it. Prices, trials
/// and the onboarding exit offer all come from the store through the current
/// offering, so Luuk changes them in RevenueCat, not in a build. With no SDK
/// key (or no offerings yet) the paywall shows [fallbackOffers] and buying
/// explains that purchases open later; the free tier applies.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config.dart';
import '../notifications/lifecycle.dart';

enum Plan { free, monthly, yearly, lifetime }

/// Which plan an entitlement's product grants. Product ids are ours to name,
/// so a substring is enough: `cropsy_lifetime`, `cropsy_monthly`, the rest yearly.
Plan planForProduct(String productId) {
  final id = productId.toLowerCase();
  if (id.contains('lifetime')) return Plan.lifetime;
  if (id.contains('month')) return Plan.monthly;
  return Plan.yearly;
}

/// A store period as whole days. A month is 30 and a year 365: only ever used
/// for trial lengths, where the store rounds the same way.
int periodDays(PeriodUnit unit, int n) => switch (unit) {
      PeriodUnit.day => n,
      PeriodUnit.week => 7 * n,
      PeriodUnit.month => 30 * n,
      PeriodUnit.year => 365 * n,
      PeriodUnit.unknown => 0,
    };

/// "Save 58%": yearly against twelve months of monthly, rounded down so it
/// never overpromises. Null when there is nothing to save.
int? savingsPercent(double yearly, double monthly) {
  if (monthly <= 0) return null;
  final pct = ((1 - yearly / (monthly * 12)) * 100).floor();
  return pct > 0 ? pct : null;
}

String formatPrice(double amount, String currency, String locale) =>
    NumberFormat.simpleCurrency(locale: locale, name: currency).format(amount);

/// The trial timeline's middle row: the reminder goes out two days before the
/// charge, never before day 1.
int reminderDay(int trialDays) => trialDays - 2 < 1 ? 1 : trialDays - 2;

/// One row on the paywall: a store package, or a fallback price before the
/// store answers. [package] null means "can't be bought from here".
class PlanOffer {
  const PlanOffer({
    required this.plan,
    required this.price,
    required this.currency,
    this.priceString,
    this.trialDays = 0,
    this.package,
  });

  factory PlanOffer.of(Plan plan, Package p) {
    final s = p.storeProduct;
    return PlanOffer(
      plan: plan,
      price: s.price,
      currency: s.currencyCode,
      priceString: s.priceString,
      trialDays: _trialDays(s),
      package: p,
    );
  }

  final Plan plan;
  final double price;
  final String currency;
  final String? priceString;
  final int trialDays;
  final Package? package;

  /// The billed amount, as the store writes it when it has spoken.
  String billed(String locale) => priceString ?? formatPrice(price, currency, locale);

  String perMonth(String locale) => formatPrice(price / 12, currency, locale);
}

/// A free intro offer, in days. iOS says it with `introductoryPrice`; on
/// Android a trial is a free phase of the default subscription option.
int _trialDays(StoreProduct s) {
  final intro = s.introductoryPrice;
  if (intro != null && intro.price == 0) return periodDays(intro.periodUnit, intro.periodNumberOfUnits);
  final free = s.defaultOption?.freePhase?.billingPeriod;
  return free == null ? 0 : periodDays(free.unit, free.value);
}

/// What the paywall shows before (or without) RevenueCat. Euros, the launch
/// prices; the store's own numbers replace these the moment offerings load.
const fallbackOffers = [
  PlanOffer(plan: Plan.yearly, price: 39.99, currency: 'EUR', trialDays: 7),
  PlanOffer(plan: Plan.monthly, price: 7.99, currency: 'EUR'),
  PlanOffer(plan: Plan.lifetime, price: 99.99, currency: 'EUR'),
];

/// The onboarding exit offer: a discounted first year, then [regular].
typedef ExitOffer = ({Package package, String price, String regular});

class PurchaseService extends ChangeNotifier {
  bool configured = false;
  Plan plan = Plan.free;
  Offerings? offerings;
  String? lastError;

  /// Best effort: iOS can tell us someone already used their trial; Android
  /// simply won't offer the free phase again. Unknown counts as eligible.
  bool trialEligible = true;

  bool get premium => plan != Plan.free;

  /// Free-tier limits (PRD §9). Unlimited when premium.
  int get maxGardens => premium ? 1 << 30 : 1;
  int get maxGrowingPlants => premium ? 1 << 30 : 3;
  int get maxPhotos => premium ? 1 << 30 : 20;
  int? get freezesPerMonth => premium ? null : 2;

  /// Yearly, monthly, lifetime, whichever the current offering has, in that
  /// order. A package missing from the offering is simply not shown.
  List<PlanOffer> get offers {
    final c = offerings?.current;
    final live = [
      if (c?.annual case final p?) PlanOffer.of(Plan.yearly, p),
      if (c?.monthly case final p?) PlanOffer.of(Plan.monthly, p),
      if (c?.lifetime case final p?) PlanOffer.of(Plan.lifetime, p),
    ];
    return live.isEmpty ? fallbackOffers : live;
  }

  /// Offering metadata `dismissible: false` turns the onboarding paywall hard,
  /// so a RevenueCat Experiment can test it without a new build.
  bool get dismissible => offerings?.current?.metadata['dismissible'] != false;

  /// The `exit_offer` offering's annual package. Configured as its own product
  /// whose intro offer is the discounted first year (a product has one intro
  /// offer, and the regular yearly's is the trial). Without an intro price the
  /// product's own price is the deal and the regular yearly is the anchor.
  ExitOffer? get exitOffer {
    final p = offerings?.all['exit_offer']?.annual;
    if (p == null) return null;
    final s = p.storeProduct;
    final intro = s.introductoryPrice;
    if (intro != null && intro.price > 0) return (package: p, price: intro.priceString, regular: s.priceString);
    final regular = offerings?.current?.annual?.storeProduct.priceString;
    return regular == null ? null : (package: p, price: s.priceString, regular: regular);
  }

  Future<void> init() async {
    final key = Platform.isIOS ? revenueCatIosKey : revenueCatAndroidKey;
    if (key.isEmpty) return;
    try {
      await Purchases.configure(PurchasesConfiguration(key));
      configured = true;
      Purchases.addCustomerInfoUpdateListener(_apply);
      _apply(await Purchases.getCustomerInfo());
      offerings = await Purchases.getOfferings();
      final yearly = offerings?.current?.annual?.storeProduct.identifier;
      if (Platform.isIOS && yearly != null) {
        final e = await Purchases.checkTrialOrIntroductoryPriceEligibility([yearly]);
        trialEligible = e[yearly]?.status != IntroEligibilityStatus.introEligibilityStatusIneligible;
      }
    } catch (e) {
      lastError = '$e';
    }
    notifyListeners();
  }

  /// Tie purchases to the Supabase user so they follow a sign-in.
  Future<void> logIn(String uid) async {
    if (!configured) return;
    try {
      _apply((await Purchases.logIn(uid)).customerInfo);
    } catch (e) {
      lastError = '$e';
    }
  }

  Future<void> logOut() async {
    if (!configured) return;
    try {
      _apply(await Purchases.logOut());
    } catch (_) {}
  }

  void _apply(CustomerInfo info) {
    final e = info.entitlements.active[premiumEntitlement];
    plan = e == null ? Plan.free : planForProduct(e.productIdentifier);
    notifyListeners();
  }

  /// Buy the current offering's package for [which].
  Future<bool> buy(Plan which, {String lang = 'en'}) async {
    final package = offers.where((o) => o.plan == which).firstOrNull?.package;
    if (!configured || package == null) {
      // ponytail: store errors arrive in the store's own language anyway.
      lastError = 'Product not available yet.';
      notifyListeners();
      return false;
    }
    return buyPackage(package, lang: lang);
  }

  /// Buy any package (the exit offer's included). A purchase that started a
  /// trial schedules the trial reminders in the person's language.
  Future<bool> buyPackage(Package package, {String lang = 'en'}) async {
    lastError = null;
    try {
      final info = (await Purchases.purchase(PurchaseParams.package(package))).customerInfo;
      _apply(info);
      if (info.entitlements.active[premiumEntitlement]?.periodType == PeriodType.trial) {
        await Lifecycle.scheduleTrialReminders(DateTime.now(), lang: lang);
      }
      return premium;
    } on PlatformException catch (e) {
      // Backing out of the store sheet is a choice, not an error.
      if (PurchasesErrorHelper.getErrorCode(e) != PurchasesErrorCode.purchaseCancelledError) {
        lastError = e.message ?? '$e';
      }
    } catch (e) {
      lastError = '$e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> restore() async {
    if (!configured) return false;
    try {
      _apply(await Purchases.restorePurchases());
      return premium;
    } catch (e) {
      lastError = '$e';
      notifyListeners();
      return false;
    }
  }
}
