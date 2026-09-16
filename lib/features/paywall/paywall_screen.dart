/// Soft paywall (PRD §9 / 1.9): dismissible, shown once after onboarding and
/// when a gated feature is tapped. Free is selected by default. No trial, no
/// card. Purchases go through RevenueCat once the store products exist; until
/// then the buttons explain that. The mascot never appears here (§6).
library;

import 'package:flutter/material.dart';
import '../../design/icons.dart';

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

  static const _plans = <(String, String, String)>[
    ('Free', '€0', '1 garden · 6 growing plants · full timeline, reminders and every crop · 20 photos · 2 streak freezes a month'),
    ('Lifetime', '€49.99 once', 'Unlimited gardens and plants · planner grid · diagnose · unlimited photos and freezes · export'),
    ('Yearly', '€19.99 / year', 'Everything in Lifetime, as a subscription. Cancel in the App Store any time.'),
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
              Text('One free garden,\nfree forever.', style: AppText.display(context)),
              const SizedBox(height: 8),
              Text('Pay once for more room. No trial, no card, no auto-renew surprise.', style: AppText.bodyMuted(context)),
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
                                Text(_plans[i].$1, style: AppText.heading(context, color: _plan == i ? AppColors.onAccent : AppColors.ink)),
                                const SizedBox(width: 8),
                                Text(
                                  i == 0 ? _plans[0].$2 : (purchases?.price(i == 1 ? Plan.lifetime : Plan.yearly) ?? _plans[i].$2),
                                  style: AppText.label(context, color: _plan == i ? AppColors.onAccent.withValues(alpha: 0.7) : AppColors.muted),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Text(_plans[i].$3, style: AppText.caption(context, color: _plan == i ? AppColors.onAccent : AppColors.muted)),
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
                label: _busy ? 'One moment…' : _plan == 0 ? 'Keep it free' : 'Continue with ${_plans[_plan].$1}',
                onPressed: _busy
                    ? null
                    : () async {
                        if (_plan == 0) {
                          Navigator.of(context).pop();
                          return;
                        }
                        if (purchases == null || !purchases.configured) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Purchases open with the beta. Nothing is charged yet.')),
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
                  child: Text('Restore purchases', style: AppText.caption(context)),
                ),
              ),
              Center(child: Text('Lifetime: nothing to cancel, ever.', style: AppText.caption(context))),
            ],
          ),
        ),
      ),
    );
  }
}
