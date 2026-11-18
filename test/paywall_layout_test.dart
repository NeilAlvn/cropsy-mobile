import 'package:cropsy/features/paywall/paywall_screen.dart';
import 'package:cropsy/l10n/strings.dart';
import 'package:cropsy/purchases/purchase_service.dart';
import 'package:cropsy/timing/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const exit = PlanOffer(plan: Plan.yearly, price: 24.99, currency: 'EUR', priceString: '€24.99');
  List<Plan> plans(List<PlanOffer> cards) => [for (final c in cards) c.plan];

  test('onboarding, reminder and app open get two cards, yearly first and preselected', () {
    for (final t in [PaywallTrigger.onboarding, PaywallTrigger.secondChance, PaywallTrigger.appOpen]) {
      final p = paywallPlans(t, fallbackOffers);
      expect(plans(p.cards), [Plan.yearly, Plan.monthly], reason: t.name);
      expect(p.lead.plan, Plan.yearly, reason: t.name);
    }
  });

  test('every other paywall keeps three cards with lifetime', () {
    final p = paywallPlans(PaywallTrigger.plantLimit, fallbackOffers, exit: exit);
    expect(plans(p.cards), [Plan.monthly, Plan.yearly, Plan.lifetime]);
    expect(p.lead.plan, Plan.yearly);
  });

  test('only the reminder leads with the exit offer, in place of the trial card', () {
    final p = paywallPlans(PaywallTrigger.secondChance, fallbackOffers, exit: exit);
    expect(p.lead, same(exit));
    expect(p.cards, [same(exit), isA<PlanOffer>().having((o) => o.plan, 'plan', Plan.monthly)]);
    expect(paywallPlans(PaywallTrigger.onboarding, fallbackOffers, exit: exit).lead, isNot(same(exit)));
    expect(paywallPlans(PaywallTrigger.appOpen, fallbackOffers, exit: exit).lead, isNot(same(exit)));
  });

  test('without yearly the trial layout leads with monthly alone', () {
    final p = paywallPlans(PaywallTrigger.onboarding, fallbackOffers.where((o) => o.plan != Plan.yearly).toList());
    expect(plans(p.cards), [Plan.monthly]);
    expect(p.lead.plan, Plan.monthly);
  });

  group('benefits', () {
    const tomato = LocalizedText(nl: 'Tomaat', en: 'Tomato', de: 'Tomate');
    const pepper = LocalizedText(nl: 'Paprika', en: 'Pepper', de: 'Paprika');
    const basil = LocalizedText(nl: 'Basilicum', en: 'Basil', de: 'Basilikum');
    const kale = LocalizedText(nl: 'Boerenkool', en: 'Kale', de: 'Grünkohl');
    const fallback = [Str.pwPlanner, Str.pwDiagnose];

    test('their crops, their pains, then the way out, at most four', () {
      final b = paywallBenefits(
        crops: [tomato, pepper, basil, kale],
        pains: ['timing', 'midsummer', 'overload'],
        ios: true,
        fallback: fallback,
      );
      expect(b, hasLength(4));
      expect(b.first.en, 'Every sowing and planting step for tomato, pepper and basil.');
      expect(b.first.pick('de'), contains('Tomate, Paprika und Basilikum'));
      expect(b[1].en, Str.echoTiming.en);
      expect(b.last.en, 'Cancel anytime in the App Store.');
    });

    test('nothing personal falls back to the generic list', () {
      expect(paywallBenefits(crops: [], pains: [], ios: false, fallback: fallback), fallback);
    });

    test('one crop, no list joiner; Google Play off iOS', () {
      final b = paywallBenefits(crops: [tomato], pains: ['unknown'], ios: false, fallback: fallback);
      expect([for (final l in b) l.en], ['Every sowing and planting step for tomato.', 'Cancel anytime in Google Play.']);
    });
  });

  test('the trial price line names the billed amount before the monthly one', () {
    final line = Str.pwPriceTrial(7, '€39.99', '€3.33');
    for (final lang in ['nl', 'en', 'de', 'fr', 'sv', 'pt']) {
      final t = line.pick(lang);
      expect(t.indexOf('€39.99'), lessThan(t.indexOf('€3.33')), reason: lang);
    }
  });
}
