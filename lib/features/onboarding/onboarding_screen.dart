/// Onboarding, PRD §5.1 (1.1–1.9), reworked trial-first.
///
/// hero → mascot hello with the trust line → location (postcode fallback) →
/// space → size and sun → experience → what you want to eat and why → "does
/// this sound like you?" → crops → the plan built on screen, with the rest of
/// the season shown locked → notifications, with the reason → the paywall.
///
/// GrowIt spends four screens on "do you relate?" statements; here they are
/// three toggles on one screen, and each yes is answered on the plan. Still
/// left out: the Part 1 / Part 2 chapter cards, the growing-method question
/// (asked per plant at add-plant, where the answer is actually true),
/// companion planting (on by default, in Settings) and the season-path tour,
/// which is a card on the Season tab where the path actually is. No ATT
/// prompt: we do not track. No social proof: §1.3 says drop it.
///
/// Free gardens grow a few plants at a time (PurchaseService.maxGrowingPlants). Picks over
/// that are kept as planning plants rather than dropped, and a purchase on the
/// paywall that follows promotes them to growing.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../analytics/analytics.dart';
import '../../data/frost_presets.dart';
import '../../data/seed.dart';
import '../../db/database.dart';
import '../../design/colors.dart';
import '../../design/brutal.dart';
import '../../design/components.dart';
import '../../design/crop_image.dart';
import '../../design/icons.dart';
import '../../design/mascot.dart';
import '../../design/motion.dart';
import '../../design/typography.dart';
import '../garden/log_node_flow.dart' show formatDay, nodeKindLine;
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../notifications/reminders.dart';
import '../../timing/types.dart';
import '../../timing/weather_adjust.dart' show TaskKind;
import '../location/frost_lookup.dart';
import '../paywall/paywall_screen.dart';
import '../repository_scope.dart';
import '../settings/settings_screen.dart';
import 'hero_page.dart';
import 'steps.dart';

/// Which kind of garden the answers describe. The growing-method question used
/// to feed this; it does not exist any more, so space and size decide it alone.
/// Top-level and pure so it can be checked without mounting a screen — the UI
/// itself pulls in google_fonts, which hangs under `flutter test`.
GardenKind gardenKindFor({required Set<String> spaces, required int sizeBucket}) {
  if (spaces.contains('farm') || (spaces.contains('backyard') && sizeBucket >= 2)) {
    return GardenKind.allotment;
  }
  if (spaces.contains('backyard')) return GardenKind.garden;
  return GardenKind.balcony;
}

/// How far through the questions a page is, for the bar. The hero, the hello,
/// the payoff and the reminders ask are not questions and get no bar.
double onboardingProgress(int page) => (page - _firstQuestion + 1) / _questionCount;

/// Hero, hello, seven questions, the plan, the reminders ask.
const int onboardingPageCount = 11;
const int _questionCount = 7;
const int _firstQuestion = 2;

/// The crops step's grid, in the order it is shown. That order is also which
/// picks grow first when there are more than the free garden takes.
List<String> get onboardingCropOptions => <String>{
  ...starterCrops.keys,
  'chili',
  'cucumber',
  'chives',
  'coriander',
  'beetroot',
}.toList();

/// The first [limit] picks grow now; the rest wait as planning plants. Premium
/// passes a limit nothing reaches, so it all grows.
({List<String> growing, List<String> planning}) splitPicks(Iterable<String> picks, int limit) {
  final all = picks.toList();
  return (growing: all.take(limit).toList(), planning: all.skip(limit).toList());
}

/// The "does this sound like you?" statements: id, the statement, the plan's
/// answer to it. The ids are what `preferences['pains']` stores.
const List<(String, LocalizedText, LocalizedText, IconData)> onboardingPains = [
  ('timing', Str.painTiming, Str.echoTiming, PhosphorIcons.calendarBlank),
  ('midsummer', Str.painMidsummer, Str.echoMidsummer, PhosphorIcons.sun),
  ('overload', Str.painOverload, Str.echoOverload, PhosphorIcons.magnifyingGlass),
];

/// The plan's answer to each yes, in the order the statements were asked.
List<LocalizedText> painEchoes(Iterable<String> pains) => [
  for (final (id, _, echo, _) in onboardingPains)
    if (pains.contains(id)) echo,
];

/// One row of the season preview: what, on which crop, and when.
typedef SeasonRow = (LocalizedText, String);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone, required this.onBuildingPlan});

  final VoidCallback onDone;

  /// Fired the moment the garden is about to exist. The root gate watches the
  /// repository and would otherwise swap this screen for the app the instant
  /// the garden lands, taking the plan beat and the paywall with it.
  final VoidCallback onBuildingPlan;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // The garden
  FrostRegion _region = defaultRegion;
  FrostLookup? _lookup; // GPS / postcode result, wins over the preset
  String? _postcode;
  final _spaces = <String>{'balcony'};
  int _sizeBucket = 0;
  String _sun = 'full';
  // The gardener
  String _experience = 'never';
  final _foods = <String>{'vegetables'};
  final _interests = <String>{};
  final _pains = <String>{};
  // Crops
  // Three, not all five starters: the free garden grows three, and a
  // plant-limit paywall should follow a choice the person made, not ours.
  late final Set<String> _picked = {...starterCrops.keys.take(3)};
  // The payoff
  bool _built = false;
  LocalizedText? _firstTask;
  int _matches = 0;
  List<SeasonRow> _seasonClear = const [];
  List<SeasonRow> _seasonLocked = const [];

  /// Plants over the free limit, waiting in planning until a purchase.
  final _planningIds = <String>[];

  /// The reminders ask, by index, for its own analytics event.
  static const _primingPage = onboardingPageCount - 1;

  @override
  void initState() {
    super.initState();
    Analytics.capture('onboarding_step_viewed', properties: {'step': 0});
  }

  static const _pageDuration = Duration(milliseconds: 380);
  static const _pageCurve = Curves.easeInOutCubic;

  static const _sizeBuckets = [('< 2 m²', 1), ('2–5 m²', 4), ('5–20 m²', 12), ('> 20 m²', 30)];

  void _prev() {
    if (_page > 0) _controller.previousPage(duration: _pageDuration, curve: _pageCurve);
  }

  void _next() {
    if (_page < onboardingPageCount - 1) {
      _controller.nextPage(duration: _pageDuration, curve: _pageCurve);
    } else {
      widget.onDone();
    }
  }

  GardenKind get _kind => gardenKindFor(spaces: _spaces, sizeBucket: _sizeBucket);

  /// Creates the garden + plants, saves preferences, computes the plan beat.
  Future<void> _build() async {
    widget.onBuildingPlan();
    final repo = RepositoryScope.of(context);
    final limit = PurchaseScope.maybeOf(context)?.maxGrowingPlants ?? 3;
    final gardenId = await repo.createGarden(
      region: _region,
      kind: _kind,
      sunHours: switch (_sun) {
        'full' => 8,
        'partial' => 5,
        _ => 3,
      },
      name: gardenKindLabel(_kind).pick(AppLangScope.of(context).code),
      sizeM2: _sizeBuckets[_sizeBucket].$2,
      postcode: _postcode,
      profile: _lookup?.profile,
      lat: _lookup?.lat,
      lon: _lookup?.lon,
    );
    if (_lookup != null) repo.frostSource = _lookup!.source;
    // `methods` and `companions` are no longer asked here: the place belongs to
    // the plant, and companions default on. The jsonb shape is unchanged, so
    // anything reading it keeps working — it just sees fewer keys on first run.
    await repo.saveProfile(
      preferences: {
        'spaces': _spaces.toList(),
        'sun': _sun,
        'experience': _experience,
        'foods': _foods.toList(),
        'interests': _interests.toList(),
        'pains': _pains.toList(),
      },
    );
    // Over the free limit nothing is dropped: the rest go in as planning
    // plants (no plantedOn), in the order the grid showed them.
    final split = splitPicks(onboardingCropOptions.where(_picked.contains), limit);
    for (final slug in [...split.growing, ...split.planning]) {
      final crop = repo.cropBySlug(slug);
      final growing = split.growing.contains(slug);
      final id = await repo.addPlant(
        gardenId: gardenId,
        cropSlug: slug,
        potLitres: crop?.minPotLitres?.toInt(),
        plantedOn: growing ? repo.today : null,
      );
      if (!growing) _planningIds.add(id);
    }
    final month = DateTime.now().month;
    final week = await repo.thisWeek();
    // The season preview: the next couple of real steps in the clear, then
    // what comes after them, blurred. Watering is left out of the clear rows;
    // "water the basil" is not what makes a season.
    final clear = [
      for (final t in week.where((t) => t.kind != TaskKind.water).take(2))
        (Str.stepOnCrop(kindLine(t.kind), t.cropNames), formatDay(t.due)),
    ];
    final after = week.where((t) => t.kind != TaskKind.water).take(2).lastOrNull?.due ?? '';
    final locked = [
      for (final t in (await repo.seasonTasks()).where((t) => t.node.due.compareTo(after) > 0).take(4))
        (Str.stepOnCrop(nodeKindLine(t.node.kind), repo.cropNames(t.cropSlug)), formatDay(t.node.due)),
    ];
    if (mounted) {
      setState(() {
        _built = true;
        _matches = repo.whatToGrowIn(month).length;
        _firstTask = week.isEmpty
            ? null
            : Str.stepOnCrop(kindLine(week.first.kind), week.first.cropNames);
        _seasonClear = clear;
        _seasonLocked = locked;
      });
    }
  }

  Future<void> _skip() async {
    await RepositoryScope.of(context).seedDemoGarden();
    widget.onDone();
  }

  /// The reminders ask, either answer. Both go on to the paywall.
  Future<void> _primed({required bool ask}) async {
    final granted = ask && await Reminders.requestPermission();
    Analytics.capture('notif_priming_result', properties: {'granted': granted, 'asked': ask});
    await _finish();
  }

  /// The paywall (§1.9), once, after the payoff rather than before it. It is
  /// dismissible and onboarding runs once, so that is the whole of "shown
  /// once". A purchase there lets the plants that were waiting start growing.
  Future<void> _finish() async {
    Analytics.capture('onboarding_completed', properties: {'plants_picked': _picked.length});
    final repo = RepositoryScope.of(context);
    final premium = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(
          trigger: _planningIds.isEmpty ? PaywallTrigger.onboarding : PaywallTrigger.plantLimit,
        ),
        fullscreenDialog: true,
      ),
    );
    if (premium == true) {
      for (final id in _planningIds) {
        await repo.startGrowing(id);
      }
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final limit = PurchaseScope.maybeOf(context)?.maxGrowingPlants ?? 3;
    final pages = <Widget>[
      HeroPage(
        media: const HeroMedia.image('assets/onboarding/welcome.jpg'),
        kicker: 'CROPSY',
        title: [
          TextSpan(text: Str.heroKnowWhatToDo.of(context)),
          TextSpan(
            text: Str.heroThisWeek.of(context),
            style: TextStyle(color: AppColors.accent),
          ),
          TextSpan(text: Str.heroInYourGarden.of(context)),
        ],
        subtitle: Str.heroSubtitle.of(context),
        buttonLabel: Str.getStarted.of(context),
        onNext: _next,
        // Reinstall path: sign in, sync pulls the garden, the root re-gates.
        onSkip: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),

      // ── who is asking, and why the dates can be trusted ─────────────────
      StepFrame(
        pose: MascotPose.wave,
        title: Str.getToKnowTitle,
        subtitle: Str.getToKnowBody,
        onBack: _prev,
        onSkip: _skip,
        onNext: _next,
        body: MascotNote(text: Str.datesCheckedTitle),
      ),

      // ── the garden ──────────────────────────────────────────────────────
      StepFrame(
        pose: MascotPose.pointing,
        title: Str.whereDoYouGrow,
        subtitle: Str.frostBackbone,
        progress: onboardingProgress(2),
        onBack: _prev,
        onNext: _next,
        body: _LocationStep(
          region: _region,
          lookup: _lookup,
          onRegion: (r) => setState(() {
            _region = r;
            _lookup = null;
            _postcode = null;
          }),
          onLookup: (l, pc) => setState(() {
            _lookup = l;
            _postcode = pc;
          }),
        ),
      ),
      StepFrame(
        pose: MascotPose.thinking,
        title: Str.whatSpace,
        subtitle: Str.pickAllThatApply,
        progress: onboardingProgress(3),
        enabled: _spaces.isNotEmpty,
        onBack: _prev,
        onNext: _next,
        body: ChoiceList(
          options: const [
            ('backyard', Str.spaceBackyard, PhosphorIcons.flowerLotus),
            ('balcony', Str.spaceBalcony, PhosphorIcons.buildings),
            ('indoor', Str.spaceIndoor, PhosphorIcons.browsers),
            ('farm', Str.spaceAllotment, PhosphorIcons.tractor),
            ('other', Str.spaceOther, PhosphorIcons.dotsThree),
          ],
          selected: _spaces,
          onToggle: (k) => setState(() => _spaces.contains(k) ? _spaces.remove(k) : _spaces.add(k)),
        ),
      ),
      // Two answers, one screen: both describe the same patch of ground, and
      // neither is worth a page of its own.
      StepFrame(
        pose: MascotPose.idle,
        title: Str.howMuchSpace,
        subtitle: Str.howMuchSpaceSub,
        progress: onboardingProgress(4),
        onBack: _prev,
        onNext: _next,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChoiceList(
              options: [
                for (var i = 0; i < _sizeBuckets.length; i++)
                  (
                    '$i',
                    LocalizedText(nl: _sizeBuckets[i].$1, en: _sizeBuckets[i].$1),
                    PhosphorIcons.ruler,
                  ),
              ],
              selected: {'$_sizeBucket'},
              onToggle: (k) => setState(() => _sizeBucket = int.parse(k)),
            ),
            const SizedBox(height: 18),
            GroupLabel(Str.howMuchSun),
            ChoiceList(
              options: const [
                ('full', Str.sunFull, PhosphorIcons.sun),
                ('partial', Str.sunPartial, PhosphorIcons.cloud),
                ('shade', Str.sunShade, PhosphorIcons.umbrella),
              ],
              selected: {_sun},
              onToggle: (k) => setState(() => _sun = k),
            ),
          ],
        ),
      ),

      // ── the gardener ────────────────────────────────────────────────────
      StepFrame(
        pose: MascotPose.holdingSeedling,
        title: Str.grownBefore,
        subtitle: Str.grownBeforeSub,
        progress: onboardingProgress(5),
        onBack: _prev,
        onNext: _next,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChoiceList(
              options: const [
                ('never', Str.experienceNever, PhosphorIcons.leaf),
                ('some', Str.experienceSome, PhosphorIcons.leaf),
                ('extensive', Str.experiencePlenty, PhosphorIcons.tree),
              ],
              selected: {_experience},
              onToggle: (k) => setState(() => _experience = k),
            ),
            // The one answer that deserves an answer back. GrowIt's best
            // moment, and it costs no step.
            if (_experience == 'never') ...[
              const SizedBox(height: 4),
              MascotNote(pose: MascotPose.wave, text: Str.experienceReassure),
            ],
          ],
        ),
      ),
      // What you eat and what you want out of it are the same question asked
      // twice, so they share a screen.
      StepFrame(
        pose: MascotPose.thinking,
        title: Str.whatDoYouEat,
        subtitle: Str.pickAllThatApply,
        progress: onboardingProgress(6),
        enabled: _foods.isNotEmpty,
        onBack: _prev,
        onNext: _next,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChoiceList(
              options: const [
                ('vegetables', Str.foodVegetables, PhosphorIcons.forkKnife),
                ('herbs', Str.foodHerbs, PhosphorIcons.flower),
                ('salad', Str.foodSalad, PhosphorIcons.leaf),
                ('fruit', Str.foodFruit, PhosphorIcons.appleLogo),
                ('roots', Str.foodRoots, PhosphorIcons.tree),
              ],
              selected: _foods,
              onToggle: (k) =>
                  setState(() => _foods.contains(k) ? _foods.remove(k) : _foods.add(k)),
            ),
            const SizedBox(height: 18),
            GroupLabel(Str.whatMattersMost),
            ChipWrap(
              options: const [
                ('easy', Str.interestEasy, PhosphorIcons.thumbsUp),
                ('fast', Str.interestFast, PhosphorIcons.speedometer),
                ('yield', Str.interestYield, PhosphorIcons.basket),
                ('kids', Str.interestKids, PhosphorIcons.baby),
                ('cost', Str.interestCost, PhosphorIcons.piggyBank),
              ],
              selected: _interests,
              onToggle: (k) =>
                  setState(() => _interests.contains(k) ? _interests.remove(k) : _interests.add(k)),
            ),
          ],
        ),
      ),

      // Three statements, one screen. Each yes is answered on the plan.
      StepFrame(
        pose: MascotPose.shrug,
        title: Str.painTitle,
        subtitle: Str.painSub,
        progress: onboardingProgress(7),
        onBack: _prev,
        onNext: () {
          Analytics.capture('onboarding_pains', properties: {'count': _pains.length});
          _next();
        },
        body: ChoiceList(
          options: [for (final (id, statement, _, icon) in onboardingPains) (id, statement, icon)],
          selected: _pains,
          onToggle: (k) => setState(() => _pains.contains(k) ? _pains.remove(k) : _pains.add(k)),
        ),
      ),

      StepFrame(
        pose: MascotPose.watering,
        title: Str.whatWillYouGrow,
        subtitle: Str.pickAFewToStart,
        progress: onboardingProgress(8),
        buttonLabel: Str.buildMyPlan.of(context),
        enabled: _picked.isNotEmpty,
        onBack: _prev,
        onNext: () async {
          _next();
          await _build();
        },
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlantsStep(
              picked: _picked,
              onToggle: (slug) =>
                  setState(() => _picked.contains(slug) ? _picked.remove(slug) : _picked.add(slug)),
            ),
            // Said before the plan is built, not after: what is over the
            // limit is kept, not lost, and the gardener should know which.
            if (_picked.length > limit) ...[
              const SizedBox(height: 14),
              MascotNote(text: Str.freeGrowsAtATime(limit)),
            ],
          ],
        ),
      ),

      _PlanStep(
        ready: _built,
        region: _lookup == null ? _region.name : (_postcode ?? Str.yourLocationWord.of(context)),
        frost: _lookup?.profile ?? _region.profile,
        matches: _matches,
        firstTask: _firstTask,
        echoes: painEchoes(_pains),
        seasonClear: _seasonClear,
        seasonLocked: _seasonLocked,
        onNext: _next,
      ),

      // 1.8, after the first task is visible. The trial line is a promise the
      // lifecycle notifications keep, and the honest reason to say yes.
      StepFrame(
        pose: MascotPose.pointing,
        title: Str.notifPrimingTitle,
        subtitle: Str.remindBlurb,
        buttonLabel: Str.turnOnReminders.of(context),
        onNext: () => _primed(ask: true),
        secondaryLabel: Str.notNow,
        onSecondary: () => _primed(ask: false),
        body: MascotNote(text: Str.notifPrimingTrial),
      ),
    ];
    assert(pages.length == onboardingPageCount);

    return PageView(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (p) {
        setState(() => _page = p);
        Analytics.capture('onboarding_step_viewed', properties: {'step': p});
        if (p == _primingPage) Analytics.capture('notif_priming_shown');
      },
      children: pages,
    );
  }
}

/// Where you grow, which is really "which frost dates apply". GPS first, a
/// postcode when that is refused, a region when both are.
class _LocationStep extends StatefulWidget {
  const _LocationStep({
    required this.region,
    required this.lookup,
    required this.onRegion,
    required this.onLookup,
  });
  final FrostRegion region;
  final FrostLookup? lookup;
  final ValueChanged<FrostRegion> onRegion;
  final void Function(FrostLookup lookup, String? postcode) onLookup;

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  bool _busy = false;
  String? _error;
  final _pc = TextEditingController();

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _gps() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final hit = await frostForDevice();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (hit == null) _error = Str.noLocationPickRegion.of(context);
    });
    if (hit != null) widget.onLookup(hit, null);
  }

  Future<void> _postcode() async {
    final pc = _pc.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    final hit = await frostForPostcode(pc);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (hit == null) _error = Str.postcodeNotFoundPickRegion.of(context);
    });
    if (hit != null) widget.onLookup(hit, pc.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lookup;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: (_busy ? Str.lookingUp : Str.useMyLocation).of(context),
          icon: PhosphorIcons.crosshair,
          onPressed: _busy ? null : _gps,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pc,
                textCapitalization: TextCapitalization.characters,
                style: AppText.body(context),
                decoration: InputDecoration(isDense: true, hintText: Str.postcodeHint.of(context)),
                onSubmitted: (_) => _postcode(),
              ),
            ),
            const SizedBox(width: 8),
            // A bounded width on purpose: a Row hands its non-flex children
            // infinity, and the button's own label is Flexible, which cannot lay
            // out against that. The label ellipsises if a translation is long.
            SizedBox(
              width: 116,
              child: SecondaryButton(
                label: Str.lookUp.of(context),
                onPressed: _busy ? null : _postcode,
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: AppText.caption(context, color: AppColors.critical)),
        ],
        if (l != null) ...[
          const SizedBox(height: 12),
          MascotNote(
            pose: MascotPose.celebrating,
            text: Str.foundFrostDates(
              l.profile.lastFrost.substring(5),
              l.profile.firstFrost.substring(5),
            ),
          ),
        ],
        const SizedBox(height: 18),
        GroupLabel(Str.orPickRegion),
        for (final r in frostRegions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectTile(
              icon: PhosphorIcons.mapPin,
              label: r.name,
              selected: l == null && r.name == widget.region.name,
              onTap: () => widget.onRegion(r),
            ),
          ),
      ],
    );
  }
}

class _PlantsStep extends StatelessWidget {
  const _PlantsStep({required this.picked, required this.onToggle});
  final Set<String> picked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final options = onboardingCropOptions;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [
        for (var i = 0; i < options.length; i++)
          ArriveIn(
            index: i,
            child: SelectTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(Neo.radiusThumb),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CropImage(slug: options[i], category: repo.cropCategory(options[i])),
                ),
              ),
              label: repo.cropNames(options[i]).of(context),
              selected: picked.contains(options[i]),
              onTap: () => onToggle(options[i]),
            ),
          ),
      ],
    );
  }
}

/// 1.7: the mascot builds the plan on screen, answers each "sounds like me",
/// and shows the start of the season with the rest of it locked.
class _PlanStep extends StatelessWidget {
  const _PlanStep({
    required this.ready,
    required this.region,
    required this.frost,
    required this.matches,
    required this.firstTask,
    required this.echoes,
    required this.seasonClear,
    required this.seasonLocked,
    required this.onNext,
  });

  final bool ready;
  final String region;
  final FrostProfile frost;
  final int matches;
  final LocalizedText? firstTask;
  final List<LocalizedText> echoes;
  final List<SeasonRow> seasonClear;
  final List<SeasonRow> seasonLocked;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scrolls: a long German frost line plus three answers plus the
            // season does not fit a small phone.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SeedBurst(
                      play: ready,
                      child: Mascot(ready ? MascotPose.celebrating : MascotPose.thinking, size: 104),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    (ready ? Str.planReady : Str.planBuilding).of(context),
                    style: AppText.display(context),
                  ),
                  const SizedBox(height: 16),
                  _Line(
                    done: true,
                    label: Text(
                      Str.planFrostLine(
                        region,
                        frost.lastFrost.substring(5),
                        frost.firstFrost.substring(5),
                      ).of(context),
                      style: AppText.body(context),
                    ),
                  ),
                  _Line(
                    done: ready,
                    // The one number that is the payoff, so it lands rather
                    // than appears.
                    label: ready
                        ? CountUp(
                            value: matches,
                            text: (n) => Str.planMatches(n).of(context),
                            style: AppText.body(context),
                          )
                        : Text(Str.planMatching.of(context), style: AppText.body(context)),
                  ),
                  _Line(
                    done: ready,
                    label: Text(
                      (ready
                              ? (firstTask == null
                                    ? Str.planFirstTaskWaits
                                    : Str.planFirstTask(firstTask!.of(context)))
                              : Str.planFindingFirstTask)
                          .of(context),
                      style: AppText.body(context),
                    ),
                  ),
                  for (final e in echoes)
                    _Line(
                      done: ready,
                      label: Text(e.of(context), style: AppText.body(context)),
                    ),
                  if (ready) ...[
                    const SizedBox(height: 18),
                    GroupLabel(Str.yourSeason),
                    for (final r in seasonClear) _SeasonRowTile(r),
                    _LockedSeason(rows: seasonLocked),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: ready
                  ? PrimaryButton(
                      label: Str.continueLabel.of(context),
                      icon: PhosphorIcons.arrowRight,
                      onPressed: onNext,
                    )
                  : Center(child: CircularProgressIndicator(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rest of the season, there but not readable: real rows where the plan
/// has them, blank bars where it does not. Nothing in the clear is invented,
/// and screen readers skip what sighted users cannot read either.
class _LockedSeason extends StatelessWidget {
  const _LockedSeason({required this.rows});
  final List<SeasonRow> rows;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      ExcludeSemantics(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Column(
            children: [for (var i = 0; i < 4; i++) _SeasonRowTile(i < rows.length ? rows[i] : null)],
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Neo.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.lock, size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(Str.fullSeasonPlan.of(context), style: AppText.label(context)),
            ),
          ],
        ),
      ),
    ],
  );
}

/// One season step. Null draws the bars of a row with nothing in it.
class _SeasonRowTile extends StatelessWidget {
  const _SeasonRowTile(this.row);
  final SeasonRow? row;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.tile,
      borderRadius: BorderRadius.circular(Neo.radiusTile),
    ),
    child: Row(
      children: [
        Icon(PhosphorIcons.calendarBlank, size: 20, color: AppColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: row == null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(height: 12, color: AppColors.hairline),
                  ),
                )
              : Text(
                  row!.$1.of(context),
                  style: AppText.label(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        if (row != null) ...[
          const SizedBox(width: 8),
          Text(row!.$2, style: AppText.caption(context, color: AppColors.inkMuted)),
        ],
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.done, required this.label});
  final bool done;
  final Widget label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(
          done ? PhosphorIcons.checkCircle : PhosphorIcons.circle,
          color: done ? AppColors.accent : AppColors.hairline,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(child: label),
      ],
    ),
  );
}
