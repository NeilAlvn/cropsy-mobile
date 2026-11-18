/// The paywall, on one screen: the mascot and a headline that names the
/// person's own crops, a Free | Premium table, a strip with the free week (or
/// what yearly saves), three plan cards with yearly raised in the middle and
/// preselected, and the button with its terms. Only a phone too short for all
/// of it scrolls. Dismissible unless the onboarding offering says otherwise
/// (`dismissible: false` in RevenueCat metadata, for an Experiment). On the
/// way out of onboarding the exit offer may show once. Prices come from the
/// store; without it the launch prices show and buying explains.
///
/// Onboarding, the reminder and the app-open paywall use the trial layout
/// instead ([trialLayout]): personal ticks, two cards with the free week
/// preselected, one price line, and the X as the only way out.
///
/// No switches at all: App Review 3.1.2 rejects a "free trial" toggle, and a
/// reminder toggle reads like one. The trial-end reminder is a plain line,
/// shown only when notifications are allowed to deliver it.
library;

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
import '../../design/mascot.dart';
import '../../design/motion.dart';
import '../../design/typography.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/region.dart';
import '../../l10n/strings.dart';
import '../../notifications/lifecycle.dart';
import '../../purchases/purchase_service.dart';
import '../../timing/types.dart';
import '../onboarding/onboarding_screen.dart' show painEchoes;
import '../repository_scope.dart';

/// Where the paywall was opened from. Drives the headline, the benefit order,
/// the layout, analytics, and whether the exit offer may show (onboarding
/// only). [secondChance] comes from the reminder two days after onboarding,
/// [appOpen] from a free person's 2nd and 4th app open.
enum PaywallTrigger { onboarding, plantLimit, seasonView, planner, diagnose, gardenLimit, photoLimit, homeCard, settings, secondChance, appOpen }

/// The trial layout: two cards, one price line, personal ticks, no table and
/// no "continue with free". Where the person did not reach for a feature, a
/// table of what free lacks only gives them a reason to stay free.
bool trialLayout(PaywallTrigger t) =>
    t == PaywallTrigger.onboarding || t == PaywallTrigger.secondChance || t == PaywallTrigger.appOpen;

/// The cards a paywall shows and the one it opens on. The trial layout shows
/// the lead (yearly, or on [PaywallTrigger.secondChance] the exit offer) and
/// monthly; lifetime only on the others, which keep today's three.
({List<PlanOffer> cards, PlanOffer lead}) paywallPlans(PaywallTrigger trigger, List<PlanOffer> offers, {PlanOffer? exit}) {
  final yearly = offers.where((o) => o.plan == Plan.yearly).firstOrNull;
  if (!trialLayout(trigger)) return (cards: cardOrder(offers), lead: yearly ?? offers.first);
  final monthly = offers.where((o) => o.plan == Plan.monthly).firstOrNull;
  final lead = (trigger == PaywallTrigger.secondChance ? exit : null) ?? yearly ?? monthly ?? offers.first;
  return (cards: [lead, if (monthly != null && monthly != lead) monthly], lead: lead);
}

/// The ticks on the trial layout: their crops, the answer to each pain they
/// said yes to, then the way out, at most four. Nothing personal falls back
/// to [fallback], the generic list.
List<LocalizedText> paywallBenefits({
  required List<LocalizedText> crops,
  required Iterable<String> pains,
  required bool ios,
  required List<LocalizedText> fallback,
}) {
  final personal = [
    if (crops.isNotEmpty) Str.pwBenefitCrops(crops.take(3).toList()),
    ...painEchoes(pains),
  ];
  if (personal.isEmpty) return fallback;
  // The cancel line survives the cap: it answers the fear behind a trial.
  return [...personal.take(3), Str.pwBenefitCancel(ios: ios)];
}

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.trigger = PaywallTrigger.settings});

  final PaywallTrigger trigger;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Plan? _plan; // null until the first build picks the leading offer
  bool _busy = false;
  bool _canRemind = false; // notifications allowed, so the trial reminder will arrive

  // What the person already has, for the benefit list.
  int _crops = 0;
  bool _firstSeason = false;
  List<LocalizedText> _cropNames = const [];
  List<String> _pains = const [];

  @override
  void initState() {
    super.initState();
    Analytics.capture('paywall_shown', properties: {'trigger': widget.trigger.name});
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGarden());
    Lifecycle.permitted().then((ok) {
      if (mounted && ok) setState(() => _canRemind = true);
    });
  }

  Future<void> _loadGarden() async {
    final repo = RepositoryScope.of(context);
    final plants = [...await repo.growingPlants(), ...await repo.planningPlants()];
    final prefs = (await repo.profile())?.preferences;
    final answers = prefs == null ? const <String, dynamic>{} : jsonDecode(prefs) as Map<String, dynamic>;
    final slugs = {for (final p in plants) p.cropSlug};
    if (!mounted) return;
    setState(() {
      _crops = slugs.length;
      _firstSeason = answers['experience'] == 'never';
      _cropNames = [for (final s in slugs.take(3)) repo.cropNames(s)];
      _pains = [for (final p in answers['pains'] as List? ?? const []) '$p'];
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
        PaywallTrigger.secondChance => Str.pwHeadSecondChance,
        PaywallTrigger.appOpen => Str.pwHeadAppOpen,
        PaywallTrigger.onboarding || PaywallTrigger.homeCard || PaywallTrigger.settings =>
          _crops >= 2 ? Str.pwHeadCrops(_crops) : Str.pwHeadSeason,
      };

  /// The table: what free already does, then what premium adds — their crops,
  /// their season, and the feature they reached for.
  /// `true` means free has it too.
  List<(LocalizedText, bool)> _rows(String region) {
    final features = [Str.pwPlanner, Str.pwDiagnose, Str.pwUnlimited];
    final lead = switch (widget.trigger) {
      PaywallTrigger.diagnose => 1,
      PaywallTrigger.photoLimit => 2,
      _ => 0,
    };
    return [
      (Str.pwRowGuides, true),
      // Free grows three, so "all 3 you picked" would not be a premium promise.
      (_crops > 3 ? Str.pwCrops(_crops) : Str.pwUnlimitedPlants, false),
      (_firstSeason ? Str.pwFirstSeason : Str.pwSeasonFor(region), false),
      // One feature row: the paywall's word budget has no room for a second.
      (features[lead], false),
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
    final choice = await showModalBottomSheet<_ExitChoice>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => _ExitOfferSheet(offer: offer, lang: _lang, onRestore: _restoreFromSheet),
    );
    if (choice == _ExitChoice.restored) return true;
    if (choice != _ExitChoice.take || !mounted) return false;
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

  /// Restore from the exit sheet: true when something came back, so the
  /// sheet closes and the paywall closes as bought.
  Future<bool> _restoreFromSheet() async {
    final purchases = _purchases;
    if (purchases == null || !purchases.configured) return false;
    final ok = await purchases.restore();
    if (!mounted) return ok;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? Str.purchasesRestored.of(context) : purchases.lastError ?? Str.nothingToRestore.of(context)),
    ));
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
    final twoCards = trialLayout(widget.trigger);
    // The reminder paywall leads with the discounted first year when it exists.
    final exit = widget.trigger == PaywallTrigger.secondChance ? purchases?.exitOffer : null;
    final exitCard = exit == null ? null : _exitCard(exit);
    final (:cards, :lead) = paywallPlans(widget.trigger, offers, exit: exitCard);
    final selected = cards.firstWhere((o) => o.plan == _plan, orElse: () => lead);
    final trial = _trialOf(selected);
    final yearly = offers.where((o) => o.plan == Plan.yearly).firstOrNull;
    final monthly = offers.where((o) => o.plan == Plan.monthly).firstOrNull;
    final save = yearly == null || monthly == null ? null : savingsPercent(yearly.price, monthly.price);
    // The trial layout says it in the price line and the ticks instead.
    final banner = twoCards ? null : paywallBanner(trialDays: trial, savePercent: save);
    final store = _storeName;
    final price = selected.billed(lang);
    final disclosure = switch (selected.plan) {
      _ when exit != null && selected == exitCard =>
        exit.intro ? Str.pwTermsExit(exit.price, exit.regular, store) : Str.pwTermsYearly(exit.price, store),
      Plan.lifetime => Str.pwTermsLifetime(price),
      Plan.monthly => Str.pwTermsMonthly(price, store),
      _ when trial > 0 => Str.pwTermsTrial(trial, price, store),
      _ => Str.pwTermsYearly(price, store),
    };
    final priceLine = switch (selected.plan) {
      _ when exit != null && selected == exitCard =>
        exit.intro ? Str.pwPriceExit(exit.price, exit.regular) : Str.pwPriceYearly(price, selected.perMonth(lang)),
      Plan.monthly => Str.pwPriceMonthly(price),
      _ when trial > 0 => Str.pwPriceTrial(trial, price, selected.perMonth(lang)),
      _ => Str.pwPriceYearly(price, selected.perMonth(lang)),
    };
    final motion = Motion.of(context);
    // An iPhone SE or a big text setting: tighter rows, a smaller mascot.
    final compact = MediaQuery.sizeOf(context).height < 760;
    final gap = compact ? 8.0 : 12.0;
    final cardHeight = compact ? 96.0 : 108.0;

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
          // Fills the screen and spreads the slack between the sections; only
          // when the content is taller than the screen does it scroll.
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, compact ? 4 : 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(children: [
                            Mascot(_busy ? MascotPose.thinking : MascotPose.wave, size: compact ? 64 : 76),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 28),
                                child: Text(
                                  _headline.of(context),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.title(context).copyWith(fontSize: compact ? 21 : 24, height: 1.15),
                                ),
                              ),
                            ),
                          ]),
                          if (!_hard)
                            Positioned(
                              top: -8,
                              right: -14,
                              // Visible from the first frame: a close that
                              // fades in later reads as a trap, and review flags it.
                              child: IconButton(
                                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                                icon: Icon(PhosphorIcons.x, color: AppColors.ink),
                                onPressed: _dismiss,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: gap),
                      // The slack on a tall phone goes a third above the
                      // table, two thirds between the table and the plans.
                      const Spacer(),
                      if (twoCards)
                        _Benefits(
                          lines: [
                            for (final t in paywallBenefits(
                              crops: _cropNames,
                              pains: _pains,
                              ios: Platform.isIOS,
                              fallback: [
                                for (final (t, free) in _rows(RepositoryScope.of(context).regionName))
                                  if (!free) t,
                              ],
                            ))
                              t.of(context),
                          ],
                          compact: compact,
                        )
                      else
                        _CompareTable(
                          rows: [for (final (t, free) in _rows(RepositoryScope.of(context).regionName)) (t.of(context), free)],
                          compact: compact,
                        ),
                      const Spacer(flex: 2),
                      SizedBox(height: gap),
                      AnimatedSwitcher(
                        duration: motion[Motion.standard],
                        child: banner == null
                            ? const SizedBox.shrink()
                            : _Banner(key: ValueKey(banner.en), text: banner.of(context), compact: compact),
                      ),
                      // Room for the badge that sits on yearly's top edge.
                      SizedBox(height: gap + 10),
                      SizedBox(
                        height: cardHeight + 12,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final o in cards)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _PlanCard(
                                    offer: o,
                                    selected: o == selected,
                                    // The plan the paywall leads with stands taller.
                                    height: o == lead ? cardHeight + 12 : cardHeight,
                                    compact: compact,
                                    // On two cards the free week is the lead's
                                    // title, so it needs no badge on top.
                                    name: !twoCards || o != lead
                                        ? null
                                        : o == exitCard
                                            ? Str.pwFirstYear
                                            : _trialOf(o) > 0
                                                ? Str.pwTrialBadge(_trialOf(o))
                                                : null,
                                    badge: o.plan != Plan.yearly || o == exitCard
                                        ? null
                                        : _trialOf(o) > 0
                                            ? (twoCards ? null : Str.pwTrialBadge(_trialOf(o)))
                                            : Str.pwBestValue,
                                    onTap: () {
                                      if (o.plan == selected.plan) return;
                                      setState(() => _plan = o.plan);
                                      Analytics.capture('paywall_plan_selected', properties: {'plan': o.plan.name});
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (twoCards) ...[
                        SizedBox(height: compact ? 6 : 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(priceLine.of(context), style: AppText.bodySm(context)),
                        ),
                      ],
                      SizedBox(height: compact ? 2 : 6),
                      // Kept in the layout when there is no trial, so picking
                      // monthly does not make the button jump. Hidden too when
                      // notifications are off: then the reminder would not come.
                      AnimatedOpacity(
                        opacity: trial > 0 && _canRemind ? 1 : 0,
                        duration: motion[Motion.standard],
                        child: SizedBox(
                          height: compact ? 28 : 32,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(PhosphorIcons.bell, color: AppColors.accent, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(Str.pwRemindMe.of(context), style: AppText.caption(context)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 6),
                      _Pulse(
                        child: PrimaryButton(
                          label: _busy
                              ? Str.oneMoment.of(context)
                              : (selected == exitCard
                                      ? Str.pwExitCta
                                      : trial > 0
                                          ? Str.pwCtaTrial(trial)
                                          : Str.pwCtaPlan(selected.plan.name, price))
                                  .of(context),
                          // Fallback prices are not buyable outside the eurozone.
                          onPressed: _busy || (selected.isFallback && !AppRegion.euro) ? null : () => _buy(selected),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // App Review 3.1.2: renewal terms beside the button, plus the
                      // terms of use and the privacy policy.
                      // At least three lines reserved, so the shorter monthly
                      // terms do not shift the cards; never capped, because the
                      // Portuguese trial terms need a fourth on an iPhone SE.
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: 3 * 11.5 * 1.3 * MediaQuery.textScalerOf(context).scale(1)),
                        child: Text(
                          disclosure.of(context),
                          style: AppText.caption(context).copyWith(fontSize: 11.5, height: 1.3),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // One row, shrunk rather than wrapped: a wrap left
                      // "Privacy" alone on a second line in most languages.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          // The trial layout's only way out is the X.
                          if (!_hard && !twoCards) _link(context, Str.pwContinueFree.of(context), _dismiss),
                          _link(context, Str.restorePurchases.of(context), purchases?.configured == true ? _restore : null),
                          ..._legalLinks(context, lang),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

String get _storeName => Platform.isIOS ? 'App Store' : 'Google Play';

/// The exit offer as a card: its first-year price is what it charges now.
PlanOffer _exitCard(ExitOffer exit) {
  final s = exit.package.storeProduct;
  return PlanOffer(
    plan: Plan.yearly,
    price: exit.intro ? s.introductoryPrice!.price : s.price,
    currency: s.currencyCode,
    priceString: exit.price,
    package: exit.package,
  );
}

Widget _link(BuildContext context, String label, VoidCallback? onTap) => TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 44)),
      child: Text(label, style: AppText.caption(context)),
    );

/// Terms of use and privacy policy. App Review wants both on every screen
/// that sells, the exit offer included.
List<Widget> _legalLinks(BuildContext context, String lang) => [
      for (final (label, path) in const [(Str.terms, '/terms'), (Str.privacy, '/privacy')])
        _link(
          context,
          label.of(context),
          () => launchUrl(Uri.parse('$websiteUrl/$lang$path'), mode: LaunchMode.externalApplication),
        ),
    ];

/// The strip between the table and the plans: the free week when the selected
/// plan really carries one, else what yearly saves, else nothing.
LocalizedText? paywallBanner({required int trialDays, int? savePercent}) => trialDays > 0
    ? Str.pwBannerTrial
    : savePercent == null
        ? null
        : Str.pwBannerSave(savePercent);

/// Free | Premium. The premium column is a green band down the right; its
/// ticks pop in once the rows have arrived.
class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.rows, required this.compact});

  final List<(String, bool)> rows;
  final bool compact;

  static const _freeWidth = 52.0;
  static const _premiumWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    final rowHeight = compact ? 34.0 : 42.0;
    final style = AppText.bodySm(context).copyWith(fontSize: compact ? 13 : 14, height: 1.2);
    Widget cell(double width, Widget child) => SizedBox(width: width, child: Center(child: child));
    return Container(
      decoration: Neo.box(r: Neo.radiusTile),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: _premiumWidth,
          child: ColoredBox(color: AppColors.accent),
        ),
        Column(children: [
          SizedBox(
            height: rowHeight - 4,
            child: Row(children: [
              const Spacer(),
              cell(_freeWidth, Text(Str.planFree.of(context), style: AppText.kicker(context))),
              cell(
                _premiumWidth,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(Str.pwPremiumCol.of(context), style: AppText.kicker(context, color: AppColors.onAccent)),
                ),
              ),
            ]),
          ),
          for (final (i, (label, free)) in rows.indexed)
            ArriveIn(
              index: i + 1,
              child: SizedBox(
                height: rowHeight,
                child: Row(children: [
                  const SizedBox(width: 14),
                  Expanded(child: Text(label, style: style, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  cell(
                    _freeWidth,
                    free
                        ? Icon(PhosphorIcons.check, color: AppColors.inkMuted, size: 18)
                        : Icon(PhosphorIcons.lock, color: AppColors.inkPlaceholder, size: 15),
                  ),
                  cell(_premiumWidth, _Pop(index: i, child: Icon(PhosphorFill.checkCircle, color: AppColors.onAccent, size: 20))),
                ]),
              ),
            ),
          const SizedBox(height: 6),
        ]),
      ]),
    );
  }
}

/// The trial layout's ticks: one line each, arriving like the table's rows.
class _Benefits extends StatelessWidget {
  const _Benefits({required this.lines, required this.compact});

  final List<String> lines;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = AppText.body(context).copyWith(fontSize: compact ? 14 : 15, height: 1.3);
    return Column(children: [
      for (final (i, line) in lines.indexed)
        ArriveIn(
          index: i,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 5 : 7),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Pop(index: i, child: Icon(PhosphorFill.checkCircle, color: AppColors.accent, size: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text(line, style: style)),
            ]),
          ),
        ),
    ]);
  }
}

/// A tick that springs in after its row has arrived.
class _Pop extends StatelessWidget {
  const _Pop({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Motion.of(context).reduced) return child;
    final delay = 200 + 60 * index;
    const run = 350;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: delay + run),
      curve: Interval(delay / (delay + run), 1, curve: Curves.easeOutBack),
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: child,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 30 : 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: Neo.box(color: AppColors.accentSoft, r: Neo.radiusPill),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(PhosphorFill.sealCheck, color: AppColors.onAccentSoft, size: 16),
          const SizedBox(width: 6),
          Text(text, style: AppText.label(context, color: AppColors.onAccentSoft)),
        ]),
      ),
    );
  }
}

/// One plan as a card. The billed amount is the loudest thing on it (3.1.2);
/// the per-month figure or the billing note sits under it, smaller.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.offer,
    required this.selected,
    required this.height,
    required this.compact,
    required this.onTap,
    this.badge,
    this.name,
  });

  final PlanOffer offer;
  final bool selected;
  final double height;
  final bool compact;
  final LocalizedText? badge;
  final VoidCallback onTap;

  /// Replaces the plan's own name, e.g. "7 days free" on the trial layout.
  final LocalizedText? name;

  @override
  Widget build(BuildContext context) {
    final lang = AppLangScope.of(context).code;
    final motion = Motion.of(context);
    final (name, note) = switch (offer.plan) {
      Plan.monthly => (Str.planMonthly, Str.pwBilledMonthly),
      Plan.lifetime => (Str.planLifetime, Str.pwPayOnce),
      _ => (Str.planYearly, Str.pwPerMonth(offer.perMonth(lang))),
    };
    Widget fit(Widget child) => FittedBox(fit: BoxFit.scaleDown, child: child);
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1 : 0.96,
          duration: motion[Motion.standard],
          curve: Motion.easeEnter,
          child: Stack(clipBehavior: Clip.none, children: [
            AnimatedContainer(
              duration: motion[Motion.standard],
              curve: Motion.easeEnter,
              height: height,
              // Full cell width: a Stack sizes to this box, and without it each
              // card would shrink to its own text and the row would go ragged.
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentSoft : AppColors.surface,
                borderRadius: BorderRadius.circular(Neo.radiusTile),
                border: Border.all(color: selected ? AppColors.accent : AppColors.hairline, width: selected ? 2 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                fit(Text((this.name ?? name).of(context), style: AppText.label(context, color: selected ? AppColors.onAccentSoft : AppColors.ink))),
                const SizedBox(height: 4),
                fit(Text(
                  offer.billed(lang),
                  style: AppText.heading(context).copyWith(fontSize: compact ? 19 : 21, fontWeight: FontWeight.w700),
                )),
                const SizedBox(height: 2),
                fit(Text(note.of(context), style: AppText.caption(context).copyWith(fontSize: 12))),
              ]),
            ),
            if (badge != null)
              Positioned(
                top: -11,
                left: 6,
                right: 6,
                child: Center(
                  child: fit(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: Neo.box(color: AppColors.accent, r: Neo.radiusPill),
                    child: Text(badge!.of(context), style: AppText.kicker(context, color: AppColors.onAccent)),
                  )),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// A slow swell on the button while the person reads, so the eye lands there
/// last. Nothing under reduced motion.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = Motion.of(context).reduced;
    if (!reduced && _c == null) {
      _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    } else if (reduced && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    return AnimatedBuilder(
      animation: c,
      builder: (context, child) => Transform.scale(scale: 1 + 0.02 * Curves.easeInOut.transform(c.value), child: child),
      child: widget.child,
    );
  }
}

enum _ExitChoice { take, restored }

class _ExitOfferSheet extends StatelessWidget {
  const _ExitOfferSheet({required this.offer, required this.lang, required this.onRestore});

  final ExitOffer offer;
  final String lang;
  final Future<bool> Function() onRestore;

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
          PrimaryButton(label: Str.pwExitCta.of(context), onPressed: () => Navigator.of(context).pop(_ExitChoice.take)),
          const SizedBox(height: 8),
          // Its own purchase screen, so the same App Review 3.1.2 disclosure
          // as the paywall: what renews, at what price, how to cancel.
          Text(
            (offer.intro
                    ? Str.pwTermsExit(offer.price, offer.regular, _storeName)
                    : Str.pwTermsYearly(offer.price, _storeName))
                .of(context),
            style: AppText.caption(context).copyWith(fontSize: 11.5, height: 1.3),
            textAlign: TextAlign.center,
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _link(context, Str.pwExitNo.of(context), () => Navigator.of(context).pop()),
                // App Review wants a restore on every screen that sells.
                _link(context, Str.restorePurchases.of(context), () async {
                  final navigator = Navigator.of(context);
                  if (await onRestore()) navigator.pop(_ExitChoice.restored);
                }),
                ..._legalLinks(context, lang),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
