/// Onboarding, PRD §5.1 (1.1–1.9), cut to eight steps.
///
/// hero → mascot hello with the trust line → location (postcode fallback) →
/// space → size and sun → experience → what you want to eat and why → crops →
/// the plan built on screen, then notifications with the reason, then the soft
/// paywall once.
///
/// What GrowIt spends screens on and this does not: the Part 1 / Part 2 chapter
/// cards, the growing-method question (asked per plant at add-plant, where the
/// answer is actually true), companion planting (on by default, in Settings),
/// the four "do you relate?" statements, and the season-path tour, which is now
/// a card on the Season tab where the path actually is. No ATT prompt: we do
/// not track. No social proof: §1.3 says drop it.
library;

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
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../notifications/reminders.dart';
import '../../timing/types.dart';
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

/// How far through the questions a page is, for the bar. The hero, the hello
/// and the payoff are not questions and get no bar.
double onboardingProgress(int page) => (page - _firstQuestion + 1) / _questionCount;

/// Hero, hello, six questions, the plan.
const int onboardingPageCount = 9;
const int _questionCount = 6;
const int _firstQuestion = 2;

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
  // Crops
  late final Set<String> _picked = {...starterCrops.keys};
  // The payoff
  String? _firstTask;
  int _matches = 0;

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
    final gardenId = await repo.createGarden(
      region: _region,
      kind: _kind,
      sunHours: switch (_sun) {
        'full' => 8,
        'partial' => 5,
        _ => 3,
      },
      name: gardenKindLabel(_kind).pick(AppLangScope.of(context).isDutch),
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
      },
    );
    for (final slug in _picked) {
      final crop = repo.cropBySlug(slug);
      await repo.addPlant(
        gardenId: gardenId,
        cropSlug: slug,
        potLitres: crop?.minPotLitres?.toInt(),
        plantedOn: repo.today,
      );
    }
    final month = DateTime.now().month;
    final week = await repo.thisWeek();
    if (mounted) {
      setState(() {
        _matches = repo.whatToGrowIn(month).length;
        _firstTask = week.isEmpty
            ? null
            : '${week.first.kind.name} ${week.first.cropNames.en.toLowerCase()}';
      });
    }
  }

  Future<void> _skip() async {
    await RepositoryScope.of(context).seedDemoGarden();
    widget.onDone();
  }

  /// The soft paywall (§1.9), once, after the payoff rather than before it.
  /// It is dismissible and onboarding runs once, so that is the whole of
  /// "shown once".
  Future<void> _finish() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PaywallScreen(), fullscreenDialog: true));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
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
            ChoiceList(
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

      StepFrame(
        pose: MascotPose.watering,
        title: Str.whatWillYouGrow,
        subtitle: Str.pickAFewToStart,
        progress: onboardingProgress(7),
        buttonLabel: Str.buildMyPlan.of(context),
        enabled: _picked.isNotEmpty,
        onBack: _prev,
        onNext: () async {
          _next();
          await _build();
        },
        body: _PlantsStep(
          picked: _picked,
          onToggle: (slug) =>
              setState(() => _picked.contains(slug) ? _picked.remove(slug) : _picked.add(slug)),
        ),
      ),

      _PlanStep(
        ready: _firstTask != null || _matches > 0,
        region: _lookup == null ? _region.name : (_postcode ?? Str.yourLocationWord.of(context)),
        frost: _lookup?.profile ?? _region.profile,
        matches: _matches,
        firstTask: _firstTask,
        onDone: () async {
          await Reminders.requestPermission();
          Analytics.capture('onboarding_completed', properties: {'plants_picked': _picked.length});
          await _finish();
        },
        onLater: _finish,
      ),
    ];
    assert(pages.length == onboardingPageCount);

    return PageView(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (p) => setState(() => _page = p),
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
    final options = <String>{
      ...starterCrops.keys,
      'chili',
      'cucumber',
      'chives',
      'coriander',
      'beetroot',
    }.toList();
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

/// 1.7 + 1.8: the mascot builds the plan on screen, then asks for
/// notifications with the reason — after the first task is visible.
class _PlanStep extends StatelessWidget {
  const _PlanStep({
    required this.ready,
    required this.region,
    required this.frost,
    required this.matches,
    required this.firstTask,
    required this.onDone,
    required this.onLater,
  });

  final bool ready;
  final String region;
  final FrostProfile frost;
  final int matches;
  final String? firstTask;
  final VoidCallback onDone;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              SeedBurst(
                play: ready,
                child: Mascot(ready ? MascotPose.celebrating : MascotPose.thinking, size: 104),
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
                // The one number that is the payoff, so it lands rather than
                // appears.
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
                                : Str.planFirstTask(firstTask!))
                          : Str.planFindingFirstTask)
                      .of(context),
                  style: AppText.body(context),
                ),
              ),
              const Spacer(),
              if (ready) ...[
                Text(Str.remindBlurb.of(context), style: AppText.bodyMuted(context)),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: Str.remindMe.of(context),
                  icon: PhosphorIcons.bell,
                  onPressed: onDone,
                ),
                const SizedBox(height: 8),
                SecondaryButton(label: Str.maybeLater.of(context), onPressed: onLater),
              ] else
                Center(child: CircularProgressIndicator(color: AppColors.accent)),
            ],
          ),
        ),
      ),
    );
  }
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
