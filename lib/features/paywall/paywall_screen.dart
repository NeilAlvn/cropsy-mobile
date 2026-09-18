/// Soft paywall (PRD §9 / 1.9): dismissible, shown once after onboarding and
/// when a gated feature is tapped. Free is selected by default. No trial, no
/// card. Purchases go through RevenueCat once the store products exist; until
/// then the buttons explain that. The mascot never appears here (§6).
library;

import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../timing/types.dart';
import '../../l10n/app_lang.dart';
import '../../design/icons.dart';

import '../../analytics/analytics.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../purchases/purchase_service.dart';
import '../repository_scope.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _plan = 0; // 0 free · 1 lifetime · 2 yearly

  @override
  void initState() {
    super.initState();
    // Top of the paid funnel; RevenueCat owns the bottom of it.
    Analytics.capture('paywall_shown');
  }

  static const _plans = <(LocalizedText, LocalizedText, LocalizedText)>[
    (Str.planFree, Str.planFreePrice, Str.planFreeBlurb),
    (Str.planLifetime, Str.planLifetimePrice, Str.planLifetimeBlurb),
    (Str.planYearly, Str.planYearlyPrice, Str.planYearlyBlurb),
  ];

  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final purchases = PurchaseScope.maybeOf(context);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(icon: Icon(PhosphorIcons.x, color: AppColors.ink), onPressed: () => Navigator.of(context).pop()),
              ),
              Text(Str.oneFreeGarden.of(context), style: AppText.display(context)),
              const SizedBox(height: 8),
              Text(Str.payOnce.of(context), style: AppText.bodyMuted(context)),
              const SizedBox(height: 20),
              for (var i = 0; i < _plans.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _plan = i),
                    child: Container(
                      decoration: Neo.box(color: _plan == i ? AppColors.sprout : AppColors.surface),
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(_plans[i].$1.of(context), style: AppText.heading(context, color: _plan == i ? AppColors.onAccent : AppColors.ink)),
                                const SizedBox(width: 8),
                                Text(
                                  i == 0
                                      ? _plans[0].$2.of(context)
                                      : (purchases?.price(i == 1 ? Plan.lifetime : Plan.yearly) ??
                                          _plans[i].$2.of(context)),
                                  style: AppText.label(context, color: _plan == i ? AppColors.onAccent.withValues(alpha: 0.7) : AppColors.muted),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Text(_plans[i].$3.of(context), style: AppText.caption(context, color: _plan == i ? AppColors.onAccent : AppColors.muted)),
                            ],
                          ),
                        ),
                        Icon(_plan == i ? PhosphorIcons.checkCircle : PhosphorIcons.circle, color: _plan == i ? AppColors.onAccent : AppColors.hairline),
                      ]),
                    ),
                  ),
                ),
              const Spacer(),
              PrimaryButton(
                label: _busy
                    ? Str.oneMoment.of(context)
                    : _plan == 0
                        ? Str.keepItFree.of(context)
                        : Str.continueWith(_plans[_plan].$1.of(context)).of(context),
                onPressed: _busy
                    ? null
                    : () async {
                        if (_plan == 0) {
                          Navigator.of(context).pop();
                          return;
                        }
                        if (purchases == null || !purchases.configured) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(Str.purchasesOpenLater.of(context))),
                          );
                          return;
                        }
                        setState(() => _busy = true);
                        final ok = await purchases.buy(_plan == 1 ? Plan.lifetime : Plan.yearly);
                        if (!context.mounted) return;
                        setState(() => _busy = false);
                        if (ok) {
                          Navigator.of(context).pop(true);
                        } else if (purchases.lastError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(purchases.lastError!)));
                        }
                      },
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: purchases?.configured == true ? () => purchases!.restore() : null,
                  child: Text(Str.restorePurchases.of(context), style: AppText.caption(context)),
                ),
              ),
              Center(child: Text(Str.lifetimeNothingEver.of(context), style: AppText.caption(context))),
            ],
          ),
        ),
      ),
    );
  }
}
