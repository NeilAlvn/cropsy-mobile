/// The paywall. Trial-first: yearly with a free week is preselected, the
/// headline sells the season the person just built, and the benefits name
/// their own crops. Dismissible unless the onboarding offering says otherwise
/// (`dismissible: false` in RevenueCat metadata, for an Experiment). On the
/// way out of onboarding the exit offer may show once. Prices come from the
/// store; without it the launch prices show and buying explains. The mascot
/// never appears here (§6).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show Package;
import 'package:url_launcher/url_launcher.dart';

import '../../analytics/analytics.dart';
import '../../config.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/icons.dart';
import '../../design/typography.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../purchases/purchase_service.dart';
import '../../timing/types.dart';
import '../repository_scope.dart';

/// Where the paywall was opened from. Drives the headline, the benefit order,
/// analytics, and whether the exit offer may show (onboarding only).
enum PaywallTrigger { onboarding, plantLimit, seasonView, planner, diagnose, gardenLimit, photoLimit, homeCard, settings }

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.trigger = PaywallTrigger.settings});

  final PaywallTrigger trigger;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Plan? _plan; // null until the first build picks the leading offer
  bool _busy = false;
  bool _closeVisible = false;
  Timer? _closeTimer;

  // What the person already has, for the benefit list.
  int _crops = 0;
  bool _firstSeason = false;

  @override
  void initState() {
    super.initState();
    Analytics.capture('paywall_shown', properties: {'trigger': widget.trigger.name});
    // The X is there from the start in the tree, just faded in after a beat
    // so the offer gets read first. Normal contrast once it shows.
    _closeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _closeVisible = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGarden());
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadGarden() async {
    final repo = RepositoryScope.of(context);
    final plants = [...await repo.growingPlants(), ...await repo.planningPlants()];
    final prefs = (await repo.profile())?.preferences;
    final experience = prefs == null ? null : (jsonDecode(prefs) as Map<String, dynamic>)['experience'];
    if (!mounted) return;
    setState(() {
      _crops = {for (final p in plants) p.cropSlug}.length;
      _firstSeason = experience == 'never';
    });
  }

  PurchaseService? get _purchases => PurchaseScope.maybeOf(context);

  /// The hard variant: only onboarding, only when the offering asks for it.
  bool get _hard => widget.trigger == PaywallTrigger.onboarding && !(_purchases?.dismissible ?? true);

  String get _lang => AppLangScope.of(context).code;

  int _trialOf(PlanOffer o) => (_purchases?.trialEligible ?? true) ? o.trialDays : 0;

  LocalizedText get _headline => switch (widget.trigger) {
        PaywallTrigger.plantLimit => Str.pwHeadPlants,
        PaywallTrigger.seasonView => Str.pwHeadSeeSeason,
        PaywallTrigger.planner => Str.pwHeadPlanner,
        PaywallTrigger.diagnose => Str.pwHeadDiagnose,
        PaywallTrigger.gardenLimit => Str.pwHeadGardens,
        PaywallTrigger.photoLimit => Str.pwHeadPhotos,
        PaywallTrigger.onboarding || PaywallTrigger.homeCard || PaywallTrigger.settings => Str.pwHeadSeason,
      };

  /// Four rows: their crops, their season, then the feature they reached for
  /// ahead of the rest.
  List<(IconData, LocalizedText)> _benefits(String region) {
    final features = [
      (PhosphorIcons.squaresFour, Str.pwPlanner),
      (PhosphorIcons.camera, Str.pwDiagnose),
      (PhosphorIcons.images, Str.pwUnlimited),
    ];
    final lead = switch (widget.trigger) {
      PaywallTrigger.diagnose => 1,
      PaywallTrigger.photoLimit => 2,
      _ => 0,
    };
    return [
      (PhosphorIcons.plant, _crops >= 2 ? Str.pwCrops(_crops) : Str.pwUnlimitedPlants),
      (PhosphorIcons.calendarBlank, _firstSeason ? Str.pwFirstSeason : Str.pwSeasonFor(region)),
      features[lead],
      ...features.where((f) => f != features[lead]).take(1),
    ];
  }

  Future<void> _dismiss() async {
    if (_hard || _busy) return;
    Analytics.capture('paywall_dismissed', properties: {'trigger': widget.trigger.name});
    final bought = widget.trigger == PaywallTrigger.onboarding && await _maybeExitOffer();
    if (mounted) Navigator.of(context).pop(bought ? true : null);
  }

  /// Once per install, only from onboarding, only when the offering exists.
  Future<bool> _maybeExitOffer() async {
    final purchases = _purchases;
    final offer = purchases?.exitOffer;
    if (purchases == null || offer == null) return false;
    final repo = RepositoryScope.of(context);
    if (await repo.meta('exit_offer_shown') != null) return false;
    await repo.setMeta('exit_offer_shown', '1');
    Analytics.capture('exit_offer_shown');
    if (!mounted) return false;
    final take = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => _ExitOfferSheet(offer: offer),
    );
    if (take != true || !mounted) return false;
    Analytics.capture('exit_offer_accepted');
    return _purchase(offer.package, plan: Plan.yearly, trial: false);
  }

  Future<void> _buy(PlanOffer o) async {
    final package = o.package;
    final purchases = _purchases;
    if (purchases == null || !purchases.configured || package == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Str.purchasesOpenLater.of(context))));
      return;
    }
    if (await _purchase(package, plan: o.plan, trial: _trialOf(o) > 0) && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<bool> _purchase(Package package, {required Plan plan, required bool trial}) async {
    final purchases = _purchases!;
    final props = <String, Object>{'plan': plan.name, 'trial': trial};
    Analytics.capture('paywall_purchase_started', properties: props);
    setState(() => _busy = true);
    final ok = await purchases.buyPackage(package, lang: _lang);
    if (!mounted) return ok;
    setState(() => _busy = false);
    if (ok) {
      Analytics.capture('paywall_purchase_completed', properties: props);
    } else if (purchases.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(purchases.lastError!)));
    }
    return ok;
  }

  Future<void> _restore() async {
    final purchases = _purchases!;
    final ok = await purchases.restore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? Str.purchasesRestored.of(context) : purchases.lastError ?? Str.nothingToRestore.of(context)),
    ));
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final purchases = _purchases;
    final offers = purchases?.offers ?? fallbackOffers;
    final lang = _lang;
    final selected = offers.firstWhere((o) => o.plan == _plan, orElse: () => offers.first);
    final trial = _trialOf(selected);
    final yearly = offers.where((o) => o.plan == Plan.yearly).firstOrNull;
    final monthly = offers.where((o) => o.plan == Plan.monthly).firstOrNull;
    final save = yearly == null || monthly == null ? null : savingsPercent(yearly.price, monthly.price);
    final store = Platform.isIOS ? 'App Store' : 'Google Play';
    final price = selected.billed(lang);
    final disclosure = switch (selected.plan) {
      Plan.lifetime => Str.pwTermsLifetime(price),
      Plan.monthly => Str.pwTermsMonthly(price, store),
      _ when trial > 0 => Str.pwTermsTrial(trial, price, store),
      _ => Str.pwTermsYearly(price, store),
    };

    return PopScope(
      // Back and swipe go through _dismiss so the exit offer and analytics
      // see them; the hard variant swallows them.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _hard
                      ? null
                      : IgnorePointer(
                          ignoring: !_closeVisible,
                          child: AnimatedOpacity(
                            opacity: _closeVisible ? 1 : 0,
                            duration: const Duration(milliseconds: 400),
                            child: IconButton(
                              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                              icon: Icon(PhosphorIcons.x, color: AppColors.ink),
                              onPressed: _dismiss,
                            ),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_headline.of(context), style: AppText.display(context)),
                      const SizedBox(height: 16),
                      for (final (icon, text) in _benefits(RepositoryScope.of(context).regionName))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(PhosphorFill.checkCircle, color: AppColors.accent, size: 22),
                            const SizedBox(width: 10),
                            Expanded(child: Text(text.of(context), style: AppText.body(context))),
                            const SizedBox(width: 8),
                            Icon(icon, color: AppColors.inkMuted, size: 20),
                          ]),
                        ),
                      const SizedBox(height: 10),
                      for (final o in offers)
                        _PlanRow(
                          offer: o,
                          selected: o == selected,
                          trialDays: _trialOf(o),
                          badge: o.plan == Plan.yearly ? (save == null ? Str.pwBestValue : Str.pwSave(save)) : null,
                          onTap: () {
                            if (o.plan == _plan) return;
                            setState(() => _plan = o.plan);
                            Analytics.capture('paywall_plan_selected', properties: {'plan': o.plan.name});
                          },
                        ),
                      if (trial > 0) ...[
                        const SizedBox(height: 14),
                        _TrialTimeline(days: trial),
                      ],
                    ],
                  ),
                ),
              ),
              // Pinned: the button and the terms it binds to stay together on
              // the smallest phone, whatever the language.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Column(children: [
                  PrimaryButton(
                    label: _busy
                        ? Str.oneMoment.of(context)
                        : (trial > 0 ? Str.pwCtaTrial(trial) : Str.continueLabel).of(context),
                    onPressed: _busy ? null : () => _buy(selected),
                  ),
                  const SizedBox(height: 8),
                  // App Review 3.1.2: renewal terms beside the button, plus the
                  // terms of use and the privacy policy.
                  Text(disclosure.of(context), style: AppText.caption(context), textAlign: TextAlign.center),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      if (!_hard) _link(Str.pwContinueFree.of(context), _dismiss),
                      _link(Str.restorePurchases.of(context), purchases?.configured == true ? _restore : null),
                      for (final (label, path) in const [(Str.terms, '/terms'), (Str.privacy, '/privacy')])
                        _link(
                          label.of(context),
                          () => launchUrl(Uri.parse('$websiteUrl/$lang$path'), mode: LaunchMode.externalApplication),
                        ),
                    ],
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _link(String label, VoidCallback? onTap) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 36)),
        child: Text(label, style: AppText.caption(context)),
      );
}

/// One plan. The billed amount is the loudest price on the row (3.1.2); the
/// trial and the per-month figure sit under the name, smaller.
class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.offer,
    required this.selected,
    required this.trialDays,
    required this.onTap,
    this.badge,
  });

  final PlanOffer offer;
  final bool selected;
  final int trialDays;
  final LocalizedText? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = AppLangScope.of(context).code;
    final price = offer.billed(lang);
    final lifetime = offer.plan == Plan.lifetime;
    final (name, billed) = switch (offer.plan) {
      Plan.monthly => (Str.planMonthly, Str.pwPerMonth(price)),
      Plan.lifetime => (Str.planLifetime, Str.pwOnce(price)),
      _ => (Str.planYearly, Str.pwPerYear(price)),
    };
    final notes = [
      if (offer.plan == Plan.yearly && trialDays > 0) Str.pwTrialThen(trialDays, price).of(context),
      if (offer.plan == Plan.yearly) Str.pwPerMonth(offer.perMonth(lang)).of(context),
    ];
    final fg = selected ? AppColors.onAccent : AppColors.ink;
    final soft = selected ? AppColors.onAccent.withValues(alpha: 0.8) : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: Neo.box(color: selected ? AppColors.sprout : AppColors.surface, bordered: !selected),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: lifetime ? 10 : 14),
            child: Row(children: [
              Icon(selected ? PhosphorFill.checkCircle : PhosphorIcons.circle, color: selected ? fg : AppColors.hairline),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: Neo.box(color: selected ? AppColors.onAccent : AppColors.accentSoft, r: 6),
                      child: Text(
                        badge!.of(context),
                        style: AppText.caption(context, color: selected ? AppColors.accent : AppColors.onAccentSoft),
                      ),
                    ),
                  Text(name.of(context), style: (lifetime ? AppText.label : AppText.heading)(context, color: fg)),
                  for (final n in notes) Text(n, style: AppText.caption(context, color: soft)),
                ]),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  billed.of(context),
                  textAlign: TextAlign.end,
                  style: (lifetime ? AppText.label : AppText.heading)(context, color: fg),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Today, the reminder, the charge: what a trial actually is, in three rows.
class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (PhosphorIcons.sealCheck, Str.pwToday, Str.pwTodaySub),
      (PhosphorIcons.bell, Str.pwDay(reminderDay(days)), Str.pwRemindSub),
      (PhosphorIcons.calendarBlank, Str.pwDay(days), Str.pwChargeSub),
    ];
    return Container(
      decoration: Neo.box(),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(Str.pwHowTrialWorks.of(context), style: AppText.label(context)),
        const SizedBox(height: 10),
        for (final (icon, day, what) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${day.of(context)}  ', style: AppText.label(context)),
                  TextSpan(text: what.of(context), style: AppText.bodySm(context, color: AppColors.inkMuted)),
                ])),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _ExitOfferSheet extends StatelessWidget {
  const _ExitOfferSheet({required this.offer});

  final ExitOffer offer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Str.pwExitTitle(offer.price).of(context), style: AppText.title(context)),
          const SizedBox(height: 8),
          Text(
            offer.regular,
            style: AppText.body(context, color: AppColors.inkMuted).copyWith(decoration: TextDecoration.lineThrough),
          ),
          const SizedBox(height: 4),
          Text(Str.pwExitBody(offer.regular).of(context), style: AppText.bodyMuted(context)),
          const SizedBox(height: 20),
          PrimaryButton(label: Str.pwExitCta.of(context), onPressed: () => Navigator.of(context).pop(true)),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(Str.pwExitNo.of(context), style: AppText.caption(context)),
            ),
          ),
        ]),
      ),
    );
  }
}
