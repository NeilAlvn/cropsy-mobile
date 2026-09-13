/// Purchases (PRD §9) via RevenueCat. Three tiers: free (default), lifetime
/// €49.99 once, yearly €19.99. No trial, no card. With no SDK key configured
/// the service reports "not configured" and the free tier applies.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config.dart';

enum Plan { free, lifetime, yearly }

class PurchaseService extends ChangeNotifier {
  bool configured = false;
  Plan plan = Plan.free;
  Offerings? offerings;
  String? lastError;

  bool get premium => plan != Plan.free;

  /// Free-tier limits (PRD §9). Unlimited when premium.
  int get maxGardens => premium ? 1 << 30 : 1;
  int get maxGrowingPlants => premium ? 1 << 30 : 6;
  int get maxPhotos => premium ? 1 << 30 : 20;
  int? get freezesPerMonth => premium ? null : 2;

  Future<void> init() async {
    final key = Platform.isIOS ? revenueCatIosKey : revenueCatAndroidKey;
    if (key.isEmpty) return;
    try {
      await Purchases.configure(PurchasesConfiguration(key));
      configured = true;
      Purchases.addCustomerInfoUpdateListener(_apply);
      _apply(await Purchases.getCustomerInfo());
      offerings = await Purchases.getOfferings();
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
    if (e == null) {
      plan = Plan.free;
    } else {
      plan = e.productIdentifier.contains('lifetime') ? Plan.lifetime : Plan.yearly;
    }
    notifyListeners();
  }

  /// Buy the lifetime or annual package of the current offering.
  Future<bool> buy(Plan which) async {
    if (!configured) return false;
    final current = offerings?.current;
    final package = which == Plan.lifetime ? current?.lifetime : current?.annual;
    if (package == null) {
      lastError = 'Product not available yet.';
      notifyListeners();
      return false;
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _apply(result.customerInfo);
      return premium;
    } on PurchasesErrorCode catch (e) {
      lastError = '$e';
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

  /// Localised price strings for the paywall, or null before offerings load.
  String? price(Plan which) {
    final current = offerings?.current;
    final package = which == Plan.lifetime ? current?.lifetime : current?.annual;
    return package?.storeProduct.priceString;
  }
}
