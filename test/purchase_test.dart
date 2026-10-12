import 'package:cropsy/purchases/purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show PeriodUnit;

void main() {
  test('an entitlement product id maps to its plan', () {
    expect(planForProduct('cropsy_lifetime'), Plan.lifetime);
    expect(planForProduct('cropsy_monthly'), Plan.monthly);
    expect(planForProduct('cropsy.premium.Month'), Plan.monthly);
    expect(planForProduct('cropsy_yearly'), Plan.yearly);
    expect(planForProduct('cropsy_yearly_exit'), Plan.yearly);
  });

  test('store periods become trial days', () {
    expect(periodDays(PeriodUnit.week, 1), 7);
    expect(periodDays(PeriodUnit.day, 3), 3);
    expect(periodDays(PeriodUnit.week, 2), 14);
    expect(periodDays(PeriodUnit.month, 1), 30);
    expect(periodDays(PeriodUnit.unknown, 1), 0);
  });

  test('yearly saves against twelve months, rounded down, never negative', () {
    expect(savingsPercent(39.99, 7.99), 58); // 1 - 39.99/95.88 = 58.3%
    expect(savingsPercent(95.88, 7.99), isNull);
    expect(savingsPercent(120, 7.99), isNull);
    expect(savingsPercent(39.99, 0), isNull);
  });

  test('per-month price is a twelfth, in the store currency and app locale', () {
    const yearly = PlanOffer(plan: Plan.yearly, price: 39.99, currency: 'EUR');
    expect(yearly.perMonth('en'), '€3.33');
    expect(yearly.perMonth('de'), contains('3,33'));
    expect(yearly.billed('nl'), contains('39,99'));
    const store = PlanOffer(plan: Plan.yearly, price: 39.99, currency: 'EUR', priceString: '€39.99');
    expect(store.billed('de'), '€39.99'); // the store's own string wins
  });

  test('the reminder lands two days before the charge, never before day 1', () {
    expect(reminderDay(7), 5);
    expect(reminderDay(14), 12);
    expect(reminderDay(3), 1);
    expect(reminderDay(1), 1);
  });

  test('the fallback leads with a yearly trial', () {
    expect(fallbackOffers.first.plan, Plan.yearly);
    expect(fallbackOffers.first.trialDays, 7);
    expect(fallbackOffers.map((o) => o.plan), [Plan.yearly, Plan.monthly, Plan.lifetime]);
  });
}
