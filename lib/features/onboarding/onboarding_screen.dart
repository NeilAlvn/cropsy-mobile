/// Onboarding, PRD §5.1 (1.1–1.9), reworked trial-first.
///
/// hero → two promises, each shown with a real piece of the app → mascot
/// hello with the trust line → location (postcode fallback) → space → size and
/// sun → experience → what you want to eat and why → three "does this sound
/// like you?" cards → crops, ordered by those answers → the plan being built,
/// line by line from the answers → the plan, with the rest of the season shown
/// locked → notifications, with the reason → the paywall.
///
/// The statements are one card each, as GrowIt does them, because a yes/no
/// tap is a smaller ask than reading a list; each yes is answered on the plan. Still
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

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../analytics/analytics.dart';
import '../../data/crop_derived.dart';
import '../../data/frost_presets.dart';
import '../../data/sample_week.dart';
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
import '../grow/planting_calendar_bar.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../l10n/region.dart';
import '../../l10n/date_fmt.dart';
import '../../l10n/units.dart';
import '../../notifications/reminders.dart';
import '../../timing/dates.dart';
import '../../timing/engine.dart' show nextStart;
import '../../timing/types.dart';
import '../../timing/weather_adjust.dart' show Adjustment, AdjustAction;
import '../location/frost_lookup.dart';
import '../location/place_search.dart';
import '../location/saved_location.dart';
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

/// How far through the questions a page is, for the bar. The hero, the
/// promises, the hello, the loader, the payoff and the reminders ask are not
/// questions and get no bar.
double onboardingProgress(int page) => (page - _firstQuestion + 1) / _questionCount;

/// Hero, two promises, hello, nine questions (three of them the statement
/// cards), the plan loader, the plan, the reminders ask.
const int onboardingPageCount = 16;
const int _questionCount = 9;
const int _firstQuestion = 4;

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

/// Which crop categories each "what do you eat" answer covers. Tomatoes and
/// courgettes count as fruit: that is what a person who ticks "fruit" in spring
/// can actually pick this summer, and the grid has no berries.
const _foodCategories = <String, Set<String>>{
  'vegetables': {'fruit-veg', 'root', 'legume', 'brassica', 'allium', 'leafy', 'potato'},
  'herbs': {'herb'},
  'salad': {'leafy'},
  'fruit': {'fruit', 'fruit-veg'},
  'roots': {'root', 'potato'},
};

/// The crops grid in the order the answers ask for: what you eat first, then
/// easiest first for 'easy' and quickest to harvest for 'fast'. 'yield',
/// 'cost' and 'kids' have no crop data behind them yet, so they do not move
/// anything rather than pretend to. Ties keep [options]' order, which is also
/// what a crop the snapshot lacks falls back to.
List<String> rankCropOptions(
  List<String> options, {
  required Set<String> foods,
  required Set<String> interests,
  required Crop? Function(String slug) crop,
}) {
  final wanted = {for (final f in foods) ...?_foodCategories[f]};
  int compare(String a, String b) {
    final ca = crop(a), cb = crop(b);
    int miss(Crop? c) => c != null && wanted.contains(c.category) ? 0 : 1;
    var d = miss(ca) - miss(cb);
    if (d == 0 && interests.contains('easy')) {
      int level(Crop? c) => c == null ? Difficulty.hard.index : difficultyOf(c).index;
      d = level(ca) - level(cb);
    }
    if (d == 0 && interests.contains('fast')) {
      num days(Crop? c) => c?.harvestDaysMin ?? 1 << 20;
      d = days(ca).compareTo(days(cb));
    }
    // List.sort is not stable; the grid's own order is the last word.
    return d != 0 ? d : options.indexOf(a) - options.indexOf(b);
  }

  return [...options]..sort(compare);
}

/// The first [limit] picks grow now; the rest wait as planning plants. Premium
/// passes a limit nothing reaches, so it all grows.
/// The first step of starting a crop by [m], as a task line.
LocalizedText startLine(MethodType m) => switch (m) {
  MethodType.sowIndoor => Str.sowIndoors,
  MethodType.sowDirect => Str.sowOutdoors,
  MethodType.plant => Str.plantOutside,
  MethodType.transplant => Str.plantOut,
};

({List<String> growing, List<String> planning}) splitPicks(Iterable<String> picks, int limit) {
  final all = picks.toList();
  return (growing: all.take(limit).toList(), planning: all.skip(limit).toList());
}

/// The "does this sound like you?" statements: id, the statement, the plan's
/// answer to it, its card's icon and the mascot's face for it. The ids are
/// what `preferences['pains']` stores, and the paywall reads them.
const List<(String, LocalizedText, LocalizedText, IconData, MascotPose)> onboardingPains = [
  ('timing', Str.painTiming, Str.echoTiming, PhosphorIcons.calendarBlank, MascotPose.thinking),
  ('midsummer', Str.painMidsummer, Str.echoMidsummer, PhosphorIcons.sun, MascotPose.sun),
  ('overload', Str.painOverload, Str.echoOverload, PhosphorIcons.magnifyingGlass, MascotPose.shrug),
];

/// The plan's answer to each yes, in the order the statements were asked.
List<LocalizedText> painEchoes(Iterable<String> pains) => [
  for (final (id, _, echo, _, _) in onboardingPains)
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
  PlaceHit? _place;
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
  // Replaced by the top three of the ranked grid once the food answers are in,
  // unless the gardener has already changed the picks themselves.
  final Set<String> _picked = {...starterCrops.keys.take(3)};
  bool _picksTouched = false;
  // The payoff
  bool _built = false;
  LocalizedText? _firstTask;
  int _matches = 0;
  List<SeasonRow> _seasonClear = const [];
  List<SeasonRow> _seasonLocked = const [];

  /// In-season plants over the free limit, waiting in planning until a
  /// purchase, with the method they start by.
  final _waiting = <String, MethodType>{};

  /// The reminders ask, by index, for its own analytics event.
  static const _primingPage = onboardingPageCount - 1;

  @override
  void initState() {
    super.initState();
    Analytics.capture('onboarding_step_viewed', properties: {'step': 0});
  }

  static const _locationPage = _firstQuestion; // after the hero, promises and hello
  static const _planPage = onboardingPageCount - 2;
  static const _pageDuration = Duration(milliseconds: 380);
  static const _pageCurve = Curves.easeInOutCubic;

  static List<(String, int)> get _sizeBuckets => gardenSizeBuckets();

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

  /// The crops grid as the answers order it; also the order picks grow in.
  List<String> get _cropOrder => rankCropOptions(
    onboardingCropOptions,
    foods: _foods,
    interests: _interests,
    crop: RepositoryScope.of(context).cropBySlug,
  );

  /// What the plan calls the place: the town picked, the postcode typed, or
  /// the region preset.
  String get _placeName => _lookup == null
      ? _region.name
      : (_place?.label ?? _postcode ?? Str.yourLocationWord.of(context));

  /// The loader's lines, each one an answer given on the way here, so the wait
  /// reads as the plan being made from them rather than as a spinner.
  List<LocalizedText> get _loaderLines {
    final repo = RepositoryScope.of(context);
    final picks = _cropOrder.where(_picked.contains).toList();
    final names = [for (final s in picks.take(3)) repo.cropNames(s).of(context)].join(', ');
    return [
      Str.loaderFrost(_placeName),
      Str.loaderSowing(picks.length, picks.length > 3 ? '$names, …' : names),
      Str.loaderFitted(
        gardenKindLabel(_kind).of(context),
        switch (_sun) {
          'full' => Str.sunFull,
          'partial' => Str.sunPartial,
          _ => Str.sunShade,
        }.of(context),
      ),
      if (_pains.isNotEmpty) Str.loaderPains(_pains.length),
    ];
  }

  /// Answers one statement card. A no removes, so going back and changing an
  /// answer is honest; the event fires after the last card, as it did after
  /// the old single list.
  void _answerPain(String id, bool yes) {
    setState(() => yes ? _pains.add(id) : _pains.remove(id));
    if (id == onboardingPains.last.$1) {
      Analytics.capture('onboarding_pains', properties: {'count': _pains.length});
    }
    _next();
  }

  /// "Build my plan": on to the loader, and on from it only once both the
  /// lines have ticked through and the garden really exists. Under reduced
  /// motion the lines are all there at once, so only the build is waited for.
  Future<void> _buildWithLoader() async {
    _next();
    final wait = Motion.of(context).reduced
        ? Duration.zero
        : _PlanLoader.tick * (_loaderLines.length + 1);
    await Future.wait([_build(), Future<void>.delayed(wait)]);
    if (mounted) _controller.animateToPage(_planPage, duration: _pageDuration, curve: _pageCurve);
  }

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
      lookup: _lookup,
      placeName: _place?.label,
      country: _place?.countryCode,
    );
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
    // Each pick starts the way it can from today. In season it grows now, by
    // the method whose window is open; out of season it waits as a planning
    // plant until that window opens, so the plan never asks for a tomato
    // planted out in November. Over the free limit, in-season picks wait too,
    // and only those start on a purchase.
    final starts = <String, ({MethodType method, String start, String end, bool open})?>{
      for (final slug in _cropOrder.where(_picked.contains))
        slug: switch (repo.cropBySlug(slug)) {
          final c? => nextStart(c, repo.frost, repo.today),
          null => null,
        },
    };
    final split = splitPicks([for (final e in starts.entries) if (e.value?.open ?? false) e.key], limit);
    for (final slug in starts.keys) {
      final growing = split.growing.contains(slug);
      final id = await repo.addPlant(
        gardenId: gardenId,
        cropSlug: slug,
        potLitres: repo.cropBySlug(slug)?.minPotLitres?.toInt(),
        plantedOn: growing ? repo.today : null,
        method: growing ? starts[slug]!.method : null,
      );
      if (split.planning.contains(slug)) _waiting[id] = starts[slug]!.method;
    }
    final month = DateTime.now().month;
    // The season preview: how each pick gets started, soonest first, then
    // what the growing plants do after that, blurred.
    final firsts = [
      for (final e in starts.entries)
        if (e.value case final s?)
          (
            line: Str.stepOnCrop(startLine(s.method), repo.cropNames(e.key)),
            due: s.open ? repo.today : s.start,
          ),
    ]..sort((a, b) => a.due.compareTo(b.due));
    final clear = [for (final f in firsts.take(2)) (f.line, formatDay(f.due))];
    final after = firsts.take(2).lastOrNull?.due ?? '';
    final later = [
      for (final f in firsts.skip(2)) (line: f.line, due: f.due),
      for (final t in (await repo.seasonTasks()).where((t) => t.node.due.compareTo(after) > 0))
        (line: Str.stepOnCrop(nodeKindLine(t.node.kind), repo.cropNames(t.cropSlug)), due: t.node.due),
    ]..sort((a, b) => a.due.compareTo(b.due));
    final locked = [for (final f in later.take(4)) (f.line, formatDay(f.due))];
    if (mounted) {
      setState(() {
        _built = true;
        _matches = repo.whatToGrowIn(month).length;
        // A first step that is still weeks away says when, so a plan made in
        // November reads as a plan and not as nothing to do.
        _firstTask = switch (firsts.firstOrNull) {
          null => null,
          final f when f.due == repo.today => f.line,
          final f => Str.withDay(f.line, formatDay(f.due)),
        };
        _seasonClear = clear;
        _seasonLocked = locked;
      });
    }
  }

  Future<void> _skip() async {
    final repo = RepositoryScope.of(context);
    if (!usesNlBePresets(repo.effectiveCountry)) {
      _controller.animateToPage(_locationPage, duration: _pageDuration, curve: _pageCurve);
      return;
    }
    await repo.seedDemoGarden();
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
        // Always the onboarding trigger, also when picks wait over the free
        // limit: it carries the trial layout and the exit offer; the crop
        // benefit line already names what is waiting.
        builder: (_) => const PaywallScreen(trigger: PaywallTrigger.onboarding),
        fullscreenDialog: true,
      ),
    );
    if (premium == true) {
      for (final MapEntry(key: id, value: method) in _waiting.entries) {
        await repo.startGrowing(id, method: method);
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

      // ── what the app does, each shown with a real piece of it ───────────
      StepFrame(
        pose: MascotPose.rain,
        title: Str.promiseWeatherTitle,
        subtitle: Str.promiseWeatherBody,
        onBack: _prev,
        onNext: _next,
        body: const _WeatherPromise(),
      ),
      StepFrame(
        pose: MascotPose.holdingSeedling,
        title: Str.promiseSeasonTitle,
        subtitle: Str.promiseSeasonBody,
        onBack: _prev,
        onNext: _next,
        body: const _SeasonPromise(),
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
        subtitle: Str.frostBackbone(distanceKm(1)),
        progress: onboardingProgress(4),
        onBack: _prev,
        onNext: () {
          if (_lookup == null && !usesNlBePresets(RepositoryScope.of(context).effectiveCountry)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Str.pickPlaceFirst.of(context))));
            return;
          }
          _next();
        },
        body: _LocationStep(
          region: _region,
          lookup: _lookup,
          onRegion: (r) => setState(() {
            _region = r;
            _lookup = null;
            _postcode = null;
            _place = null;
          }),
          onLookup: (l, pc, place) => setState(() {
            _lookup = l;
            _postcode = pc;
            _place = place;
          }),
        ),
      ),
      StepFrame(
        pose: MascotPose.thinking,
        title: Str.whatSpace,
        subtitle: Str.pickAllThatApply,
        progress: onboardingProgress(5),
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
        progress: onboardingProgress(6),
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
        progress: onboardingProgress(7),
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
        progress: onboardingProgress(8),
        enabled: _foods.isNotEmpty,
        onBack: _prev,
        onNext: () {
          // The preselection follows the answers just given, until the
          // gardener picks for themselves.
          if (!_picksTouched) {
            setState(() => _picked
              ..clear()
              ..addAll(_cropOrder.take(3)));
          }
          _next();
        },
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

      // One statement a card, answered with a tap either way. Each yes is
      // answered on the plan.
      for (final (i, (id, statement, _, icon, pose)) in onboardingPains.indexed)
        StepFrame(
          pose: pose,
          title: Str.painTitle,
          progress: onboardingProgress(9 + i),
          onBack: _prev,
          body: _PainCard(statement: statement, icon: icon),
          actions: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: Str.no.of(context),
                  onPressed: () => _answerPain(id, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: Str.yes.of(context),
                  onPressed: () => _answerPain(id, true),
                ),
              ),
            ],
          ),
        ),

      StepFrame(
        pose: MascotPose.watering,
        title: Str.whatWillYouGrow,
        subtitle: Str.pickAFewToStart,
        progress: onboardingProgress(12),
        buttonLabel: Str.buildMyPlan.of(context),
        enabled: _picked.isNotEmpty,
        onBack: _prev,
        onNext: _buildWithLoader,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlantsStep(
              options: _cropOrder,
              picked: _picked,
              onToggle: (slug) => setState(() {
                _picksTouched = true;
                _picked.contains(slug) ? _picked.remove(slug) : _picked.add(slug);
              }),
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

      _PlanLoader(run: _page >= _planPage - 1, lines: _loaderLines),

      _PlanStep(
        ready: _built,
        region: _placeName,
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
  final void Function(FrostLookup lookup, String? postcode, PlaceHit? place) onLookup;

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  bool _busy = false;
  String? _error;
  List<PlaceHit> _places = const [];

  /// Bumped by every lookup; an answer that arrives after a newer lookup
  /// started is dropped, so a slow earlier search can never overwrite the pick.
  int _gen = 0;
  static final _pcPattern = RegExp(r'^[1-9]\d{3}\s?[A-Za-z]{2}$');
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
    final gen = ++_gen;
    final hit = await frostForDevice();
    if (!mounted || gen != _gen) return;
    setState(() {
      _busy = false;
      if (hit == null) _error = (AppRegion.nlBe ? Str.noLocationPickRegion : Str.placeNotFound).of(context);
    });
    if (hit != null) widget.onLookup(hit, null, null);
  }

  Future<void> _search() async {
    final pc = _pc.text.trim();
    if (!_pcPattern.hasMatch(pc)) {
      setState(() {
        _busy = true;
        _error = null;
        _places = const [];
      });
      final gen = ++_gen;
      final hits = await searchPlaces(pc, lang: AppLangScope.of(context).code);
      if (!mounted || gen != _gen) return;
      setState(() {
        _busy = false;
        _places = hits;
        if (hits.isEmpty) _error = (AppRegion.nlBe ? Str.noLocationMatch(pc) : Str.placeNotFound).of(context);
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final gen = ++_gen;
    final hit = await frostForPostcode(pc);
    if (!mounted || gen != _gen) return;
    setState(() {
      _busy = false;
      if (hit == null) _error = (AppRegion.nlBe ? Str.postcodeNotFoundPickRegion : Str.placeNotFound).of(context);
    });
    if (hit != null) widget.onLookup(hit, pc.toUpperCase(), null);
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
                textCapitalization: TextCapitalization.words,
                style: AppText.body(context),
                decoration: InputDecoration(isDense: true, hintText: Str.placeSearchHint.of(context)),
                onSubmitted: (_) => _search(),
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
                onPressed: _busy ? null : _search,
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: AppText.caption(context, color: AppColors.critical)),
        ],
        for (final p in _places)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SelectTile(
              icon: PhosphorIcons.mapPin,
              label: p.label,
              selected: false,
              onTap: () async {
                if (_busy) return;
                setState(() => _busy = true);
                final gen = ++_gen;
                final hit = await frostForCoordinate(p.lat, p.lon);
                if (!mounted || gen != _gen) return;
                setState(() {
                  _busy = false;
                  if (hit == null) _error = Str.frostLookupFailed.of(context);
                  _places = const [];
                });
                if (hit != null) widget.onLookup(hit, null, p);
              },
            ),
          ),
        if (l != null) ...[
          const SizedBox(height: 12),
          MascotNote(
            pose: MascotPose.celebrating,
            text: l.profile.regime == 'frost_free'
                ? Str.foundNoFrost
                : Str.foundFrostDates(
                    dayMonthIso(l.profile.lastFrost),
                    dayMonthIso(l.profile.firstFrost),
                  ),
          ),
        ],
        if (usesNlBePresets(RepositoryScope.of(context).effectiveCountry)) ...[
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
      ],
    );
  }
}

class _PlantsStep extends StatelessWidget {
  const _PlantsStep({required this.options, required this.picked, required this.onToggle});
  final List<String> options;
  final Set<String> picked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
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

/// One "does this sound like you?" statement, big enough to be the screen.
class _PainCard extends StatelessWidget {
  const _PainCard({required this.statement, required this.icon});
  final LocalizedText statement;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ArriveIn(
    index: 0,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(Neo.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: AppColors.accent),
          const SizedBox(height: 14),
          Text(statement.of(context), style: AppText.display(context).copyWith(fontSize: 26)),
        ],
      ),
    ),
  );
}

/// The first promise's proof: the week ahead as the app draws it, and the two
/// things the weather does to a watering. The days come from the sample
/// forecast and carry no temperatures, because those would be numbers about a
/// week that is not the reader's.
class _WeatherPromise extends StatelessWidget {
  const _WeatherPromise();

  @override
  Widget build(BuildContext context) {
    final today = RepositoryScope.of(context).today;
    // The sample starts three days back; the strip starts today.
    final days = sampleObservations(today).skip(3).take(7);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(Neo.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final d in days)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        weekdayShort(parseIso(d.date)),
                        style: AppText.caption(context, color: AppColors.inkMuted),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      d.precipMm >= 5
                          ? Icon(PhosphorIcons.cloudRain, size: 20, color: AppColors.rain)
                          : d.tempMaxC >= 28
                          ? Icon(PhosphorIcons.sun, size: 20, color: AppColors.heat)
                          : Icon(PhosphorIcons.cloudSun, size: 20, color: AppColors.inkMuted),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in [AdjustAction.skip, AdjustAction.bringForward])
                WeatherHintBadge(Adjustment(taskId: '', action: a, reason: Str.empty)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The second promise's proof: the crop page's own calendar bar for a tomato,
/// from the engine, so it is the real thing rather than a picture of it.
class _SeasonPromise extends StatelessWidget {
  const _SeasonPromise();

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final crop = repo.cropBySlug('tomato');
    if (crop == null) return MascotNote(text: Str.promiseSeasonBody);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(Neo.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(crop.names.of(context), style: AppText.label(context)),
          const SizedBox(height: 10),
          PlantingCalendarBar(crop: crop, frost: repo.frost, today: repo.today),
        ],
      ),
    );
  }
}

/// "Creating your growing plan": the answers come back as a checklist that
/// ticks through while the garden is really being made. No bar and no button;
/// the screen moves on by itself.
class _PlanLoader extends StatefulWidget {
  const _PlanLoader({required this.run, required this.lines});

  /// Time between ticks. The screen waits for one tick per line, plus one.
  static const tick = Duration(milliseconds: 800);

  /// False until the page is on screen, so the ticks are not spent unseen.
  final bool run;
  final List<LocalizedText> lines;

  @override
  State<_PlanLoader> createState() => _PlanLoaderState();
}

class _PlanLoaderState extends State<_PlanLoader> {
  Timer? _timer;
  int _done = 0;

  @override
  void didUpdateWidget(_PlanLoader old) {
    super.didUpdateWidget(old);
    if (widget.run && !old.run) _start();
  }

  void _start() {
    if (Motion.of(context).reduced) {
      setState(() => _done = widget.lines.length);
      return;
    }
    _timer = Timer.periodic(_PlanLoader.tick, (t) {
      if (_done >= widget.lines.length) {
        t.cancel();
        return;
      }
      setState(() => _done++);
      Haptics.selection();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.canvas,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
        children: [
          Align(alignment: Alignment.centerLeft, child: Mascot(MascotPose.thinking, size: 104)),
          const SizedBox(height: 22),
          Text(Str.planBuilding.of(context), style: AppText.display(context)),
          const SizedBox(height: 16),
          for (var i = 0; i < widget.lines.length; i++)
            ArriveIn(
              index: i,
              child: _Line(
                done: i < _done,
                label: Text(widget.lines[i].of(context), style: AppText.body(context)),
              ),
            ),
        ],
      ),
    ),
  );
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
                      (frost.regime == 'frost_free'
                              ? Str.planNoFrostLine(region)
                              : Str.planFrostLine(
                                  region,
                                  dayMonthIso(frost.lastFrost),
                                  dayMonthIso(frost.firstFrost),
                                ))
                          .of(context),
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
