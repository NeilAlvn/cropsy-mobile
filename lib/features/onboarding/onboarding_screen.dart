/// Onboarding to PRD §5.1 (1.1–1.8): hero → trust → mascot hello →
/// Part 1 "learn your garden" (location with postcode fallback, space type,
/// growing method, size, sun) → Part 2 "learn your preference" (experience,
/// food types, interests, companions, four statements) → pick crops →
/// "creating your plan" beat → notifications ask, with the reason, after the
/// first task is shown. No ATT prompt, no social-proof slide.
library;

import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';
import '../../design/icons.dart';

import '../../data/frost_presets.dart';
import '../../data/seed.dart';
import '../../db/database.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/crop_image.dart';
import '../../design/mascot.dart';
import '../../design/typography.dart';
import '../../notifications/reminders.dart';
import '../../timing/types.dart';
import '../location/frost_lookup.dart';
import '../repository_scope.dart';
import '../settings/settings_screen.dart';
import 'hero_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // Part 1 — garden
  FrostRegion _region = defaultRegion;
  FrostLookup? _lookup; // GPS / postcode result, wins over the preset
  String? _postcode;
  final _spaces = <String>{'balcony'};
  final _methods = <String>{'outdoor_containers'};
  int _sizeBucket = 0;
  String _sun = 'full';
  // Part 2 — preference
  String _experience = 'some';
  final _foods = <String>{'vegetables', 'herbs'};
  final _interests = <String>{'easy'};
  bool _companions = true;
  final _statements = <String, bool>{};
  // Crops
  late final Set<String> _picked = {...starterCrops.keys};
  // Plan beat
  String? _firstTask;
  int _matches = 0;

  static const _pageCount = 16;
  static const _pageDuration = Duration(milliseconds: 380);
  static const _pageCurve = Curves.easeInOutCubic;

  static const _sizeBuckets = [('< 2 m²', 1), ('2–5 m²', 4), ('5–20 m²', 12), ('> 20 m²', 30)];

  void _prev() {
    if (_page > 0) _controller.previousPage(duration: _pageDuration, curve: _pageCurve);
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _controller.nextPage(duration: _pageDuration, curve: _pageCurve);
    } else {
      widget.onDone();
    }
  }

  GardenKind get _kind {
    if (_spaces.contains('farm') || _spaces.contains('backyard') && _sizeBucket >= 2) return GardenKind.allotment;
    if (_spaces.contains('backyard')) return GardenKind.garden;
    return GardenKind.balcony;
  }

  /// Creates the garden + plants, saves preferences, computes the plan beat.
  Future<void> _build() async {
    final repo = RepositoryScope.of(context);
    final gardenId = await repo.createGarden(
      region: _region,
      kind: _kind,
      sunHours: switch (_sun) { 'full' => 8, 'partial' => 5, _ => 3 },
      name: gardenKindLabel(_kind),
      sizeM2: _sizeBuckets[_sizeBucket].$2,
      postcode: _postcode,
      profile: _lookup?.profile,
      lat: _lookup?.lat,
      lon: _lookup?.lon,
    );
    if (_lookup != null) repo.frostSource = _lookup!.source;
    await repo.saveProfile(preferences: {
      'spaces': _spaces.toList(),
      'methods': _methods.toList(),
      'sun': _sun,
      'experience': _experience,
      'foods': _foods.toList(),
      'interests': _interests.toList(),
      'companions': _companions,
      'statements': _statements,
    });
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

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HeroPage(
        media: const HeroMedia.image('assets/onboarding/welcome.jpg'),
        kicker: 'CROPSY',
        title: [
          TextSpan(text: 'Know what to do\n'),
          TextSpan(text: 'this week', style: TextStyle(color: AppColors.sprout)),
          TextSpan(text: ' in your garden.'),
        ],
        subtitle: 'Planting dates and reminders tuned to Dutch and EU weather, built for balconies and containers.',
        buttonLabel: 'Get started',
        onNext: _next,
        // Reinstall path: sign in, sync pulls the garden, the root re-gates.
        onSkip: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      _Step(
        onNext: _next,
        child: _Copy(
          pose: MascotPose.pointing,
          title: 'Every date checked against Dutch seed calendars',
          body: 'Each crop is cross-checked against at least two NL sources, IVN, Tuinadvies, zaaitijden.nl and Groei & Bloei, before it reaches you. '
              'And when life gets in the way, the plan moves with you. Nothing is ever "overdue".',
        ),
      ),
      _Step(
        onNext: _next,
        child: const _PathIntro(),
      ),
      _Step(
        onNext: _next,
        child: const _Copy(
          pose: MascotPose.wave,
          title: "Hi! Let's get to know each other",
          body: 'A few quick questions about your space and what you like to eat. Two minutes, then your plan is ready.',
        ),
      ),
      // ── Part 1 ─────────────────────────────────────────────────────
      _Step(
        onNext: _next,
        child: _LocationStep(
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
      _Step(
        enabled: _spaces.isNotEmpty,
        onNext: _next,
        child: _Choices(
          title: 'Where do you grow?',
          subtitle: 'Pick all that apply.',
          options: [('backyard', 'Garden', PhosphorIcons.flowerLotus), ('balcony', 'Balcony', PhosphorIcons.buildings), ('indoor', 'Indoors', PhosphorIcons.browsers), ('farm', 'Allotment', PhosphorIcons.tractor), ('other', 'Somewhere else', PhosphorIcons.dotsThree)],
          selected: _spaces,
          onToggle: (k) => setState(() => _spaces.contains(k) ? _spaces.remove(k) : _spaces.add(k)),
        ),
      ),
      _Step(
        enabled: _methods.isNotEmpty,
        onNext: _next,
        child: _Choices(
          title: 'How do you grow?',
          subtitle: 'Pick all that apply.',
          options: [('ground', 'In the ground', PhosphorIcons.plant), ('raised_beds', 'Raised beds', PhosphorIcons.squaresFour), ('indoor_containers', 'Pots inside', PhosphorIcons.browsers), ('outdoor_containers', 'Pots outside', PhosphorIcons.buildings)],
          selected: _methods,
          onToggle: (k) => setState(() => _methods.contains(k) ? _methods.remove(k) : _methods.add(k)),
        ),
      ),
      _Step(
        onNext: _next,
        child: _Choices(
          title: 'How much space?',
          subtitle: 'Roughly — it sets how many plants fit.',
          options: [for (var i = 0; i < _sizeBuckets.length; i++) ('$i', _sizeBuckets[i].$1, PhosphorIcons.ruler)],
          selected: {'$_sizeBucket'},
          onToggle: (k) => setState(() => _sizeBucket = int.parse(k)),
        ),
      ),
      _Step(
        onNext: _next,
        child: _Choices(
          title: 'How much sun?',
          subtitle: 'On a clear day, how long is it in direct sun?',
          options: [('full', 'Full sun (6h+)', PhosphorIcons.sun), ('partial', 'Partial (3–6h)', PhosphorIcons.cloud), ('shade', 'Shade (< 3h)', PhosphorIcons.umbrella)],
          selected: {_sun},
          onToggle: (k) => setState(() => _sun = k),
        ),
      ),
      // ── Part 2 ─────────────────────────────────────────────────────
      _Step(
        onNext: _next,
        child: _Choices(
          title: 'Grown anything before?',
          subtitle: 'So we pitch the advice right.',
          options: [('never', 'Never', PhosphorIcons.leaf), ('some', 'A season or two', PhosphorIcons.leaf), ('extensive', 'Plenty', PhosphorIcons.tree)],
          selected: {_experience},
          onToggle: (k) => setState(() => _experience = k),
        ),
      ),
      _Step(
        enabled: _foods.isNotEmpty,
        onNext: _next,
        child: _Choices(
          title: 'What do you like to eat?',
          subtitle: 'Pick all that apply.',
          options: [('vegetables', 'Vegetables', PhosphorIcons.forkKnife), ('herbs', 'Herbs', PhosphorIcons.flower), ('salad', 'Salad leaves', PhosphorIcons.leaf), ('fruit', 'Fruit', PhosphorIcons.appleLogo), ('roots', 'Root veg', PhosphorIcons.tree)],
          selected: _foods,
          onToggle: (k) => setState(() => _foods.contains(k) ? _foods.remove(k) : _foods.add(k)),
        ),
      ),
      _Step(
        onNext: _next,
        child: _Choices(
          title: "What's most important?",
          subtitle: 'Pick all that apply.',
          options: [('easy', 'Easy to grow', PhosphorIcons.thumbsUp), ('fast', 'Fast harvest', PhosphorIcons.speedometer), ('yield', 'High yield', PhosphorIcons.basket), ('kids', 'Fun with kids', PhosphorIcons.baby), ('cost', 'Saves money', PhosphorIcons.piggyBank)],
          selected: _interests,
          onToggle: (k) => setState(() => _interests.contains(k) ? _interests.remove(k) : _interests.add(k)),
        ),
      ),
      _Step(
        onNext: _next,
        child: _Choices(
          title: 'Interested in companion planting?',
          subtitle: 'We can warn when two plants dislike each other.',
          options: [('yes', 'Yes, show me', PhosphorIcons.heartStraight), ('no', 'Not now', PhosphorIcons.heartStraight)],
          selected: {_companions ? 'yes' : 'no'},
          onToggle: (k) => setState(() => _companions = k == 'yes'),
        ),
      ),
      _Step(
        onNext: _next,
        child: _Statements(
          answers: _statements,
          onAnswer: (k, v) => setState(() => _statements[k] = v),
        ),
      ),
      _Step(
        buttonLabel: 'Build my plan',
        enabled: _picked.isNotEmpty,
        onNext: () async {
          _next();
          await _build();
        },
        child: _PlantsStep(
          picked: _picked,
          onToggle: (slug) => setState(() => _picked.contains(slug) ? _picked.remove(slug) : _picked.add(slug)),
        ),
      ),
      _PlanStep(
        ready: _firstTask != null || _matches > 0,
        region: _lookup == null ? _region.name : (_postcode ?? 'your location'),
        frost: _lookup?.profile ?? _region.profile,
        matches: _matches,
        firstTask: _firstTask,
        onDone: () async {
          await Reminders.requestPermission();
          widget.onDone();
        },
        onLater: widget.onDone,
      ),
    ];
    assert(pages.length == _pageCount);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (p) => setState(() => _page = p),
            children: pages,
          ),
          if (_page < _pageCount - 1)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _FloatingHeader(page: _page, pageCount: _pageCount - 1, onBack: _prev, onSkip: _skip),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingHeader extends StatelessWidget {
  const _FloatingHeader({required this.page, required this.pageCount, required this.onBack, required this.onSkip});
  final int page;
  final int pageCount;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final first = page == 0;
    return Container(
      decoration: Neo.box(color: AppColors.surface, shadowOverride: Neo.shadowSm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          GestureDetector(
            onTap: first ? onSkip : onBack,
            child: first
                ? Text(Str.skip.of(context), style: AppText.label(context))
                : Icon(PhosphorIcons.caretLeft, size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (page + 1) / pageCount,
                minHeight: 8,
                backgroundColor: AppColors.hairline,
                valueColor: AlwaysStoppedAnimation(AppColors.sprout),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The season path, before the gardener has one: three stops and the shape of
/// the year, so the middle tab is not a surprise on first run.
class _PathIntro extends StatelessWidget {
  const _PathIntro();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Str.seasonAsOnePath.of(context),
              style: AppText.title(context)),
          const SizedBox(height: 8),
          Text(
            Str.seasonAsOnePathBody.of(context),
            style: AppText.bodyMuted(context),
          ),
          const SizedBox(height: 24),
          const _MiniPath(),
        ],
      );
}

/// A still of the path: the same badges the real one uses, three stops of it.
class _MiniPath extends StatelessWidget {
  const _MiniPath();

  static const _stops = <(String, String, String)>[
    ('sow', 'Sow lettuce', '1 Apr'),
    ('frost', 'IJsheiligen', '11 May'),
    ('harvest', 'Harvest tomato', '24 Aug'),
  ];

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < _stops.length; i++)
            Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Column(
                    children: [
                      Image.asset('assets/nodes/${_stops[i].$1}.png',
                          width: 64, height: 64, excludeFromSemantics: true),
                      if (i < _stops.length - 1)
                        SizedBox(
                          height: 24,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: AppColors.ink.withValues(alpha: 0.12),
                                  width: 4,
                                ),
                              ),
                            ),
                            child: const SizedBox(width: 4),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_stops[i].$2, style: AppText.label(context)),
                        Text(_stops[i].$3, style: AppText.caption(context)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
}

class _Step extends StatelessWidget {
  const _Step({required this.child, required this.onNext, this.buttonLabel = 'Continue', this.enabled = true});
  final Widget child;
  final String buttonLabel;
  final VoidCallback onNext;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 62),
          Expanded(child: child),
          Padding(
            padding: const EdgeInsets.all(20),
            child: PrimaryButton(label: buttonLabel, icon: PhosphorIcons.arrowRight, onPressed: enabled ? onNext : null),
          ),
        ],
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({required this.pose, required this.title, required this.body});
  final MascotPose pose;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Mascot(pose, size: 96),
          const SizedBox(height: 24),
          Text(title, style: AppText.display(context)),
          const SizedBox(height: 12),
          Text(body, style: AppText.body(context, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.title, required this.subtitle, required this.options, required this.selected, required this.onToggle});
  final String title;
  final String subtitle;
  final List<(String, String, IconData)> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(title, style: AppText.title(context)),
        const SizedBox(height: 6),
        Text(subtitle, style: AppText.bodyMuted(context)),
        const SizedBox(height: 14),
        for (final (key, label, icon) in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectTile(icon: icon, label: label, selected: selected.contains(key), onTap: () => onToggle(key)),
          ),
      ],
    );
  }
}

class _LocationStep extends StatefulWidget {
  const _LocationStep({required this.region, required this.lookup, required this.onRegion, required this.onLookup});
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

  Future<void> _gps() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final hit = await frostForDevice();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (hit == null) _error = 'No location — enter a postcode or pick a region below.';
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
      if (hit == null) _error = 'Postcode not found (1234AB) — or you are offline. Pick a region below.';
    });
    if (hit != null) widget.onLookup(hit, pc.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lookup;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(Str.whereDoYouGrow.of(context), style: AppText.title(context)),
        const SizedBox(height: 6),
        Text(Str.frostBackbone.of(context),
            style: AppText.bodyMuted(context)),
        const SizedBox(height: 14),
        PrimaryButton(label: (_busy ? Str.lookingUp : Str.useMyLocation).of(context), icon: PhosphorIcons.crosshair, onPressed: _busy ? null : _gps),
        const SizedBox(height: 10),
        Row(children: [
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
          SecondaryButton(label: Str.lookUp.of(context), onPressed: _busy ? null : _postcode),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: AppText.caption(context, color: AppColors.warn)),
        ],
        if (l != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: MascotSays(
              pose: MascotPose.celebrating,
              text: 'Found it. Last frost around ${l.profile.lastFrost.substring(5)}, first frost around ${l.profile.firstFrost.substring(5)}.',
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(Str.orPickRegion.of(context), style: AppText.label(context, color: AppColors.muted)),
        const SizedBox(height: 8),
        for (final r in frostRegions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectTile(
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

const _statementList = <(String, String)>[
  ('behind', 'I often feel behind on garden jobs.'),
  ('forget', 'I forget to water until something wilts.'),
  ('dates', "I never know when it's safe to plant out."),
  ('waste', "I buy seeds I never get round to sowing."),
];

class _Statements extends StatelessWidget {
  const _Statements({required this.answers, required this.onAnswer});
  final Map<String, bool> answers;
  final void Function(String key, bool agree) onAnswer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(Str.doYouRelate.of(context), style: AppText.title(context)),
        const SizedBox(height: 6),
        Text(Str.doYouRelateSub.of(context), style: AppText.bodyMuted(context)),
        const SizedBox(height: 14),
        for (final (key, text) in _statementList)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(children: [
                Expanded(child: Text(text, style: AppText.body(context))),
                const SizedBox(width: 8),
                _YesNo(value: answers[key], onChanged: (v) => onAnswer(key, v)),
              ]),
            ),
          ),
      ],
    );
  }
}

class _YesNo extends StatelessWidget {
  const _YesNo({required this.value, required this.onChanged});
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget b(bool v, IconData icon) => IconButton(
          onPressed: () => onChanged(v),
          icon: Icon(icon, color: value == v ? AppColors.sprout : AppColors.hairline),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [b(true, PhosphorIcons.thumbsUp), b(false, PhosphorIcons.thumbsDown)]);
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({required this.label, required this.selected, required this.onTap, this.icon, this.leadingWidget});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? leadingWidget;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onAccent : AppColors.ink;
    final Widget? leading = icon != null ? Icon(icon, size: 22, color: selected ? AppColors.onAccent : AppColors.sprout) : leadingWidget;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? AppColors.sprout : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: selected ? Neo.shadowSm : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 8)],
            Expanded(child: Text(label, style: AppText.label(context, color: fg), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Icon(selected ? PhosphorIcons.checkCircle : PhosphorIcons.circle, size: 20, color: selected ? AppColors.onAccent : AppColors.hairline),
          ],
        ),
      ),
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
    final options = <String>{...starterCrops.keys, 'chili', 'cucumber', 'chives', 'coriander', 'beetroot'}.toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(Str.whatWillYouGrow.of(context), style: AppText.title(context)),
        const SizedBox(height: 6),
        Text(Str.pickAFewToStart.of(context), style: AppText.bodyMuted(context)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.9,
          children: [
            for (final slug in options)
              _SelectTile(
                leadingWidget: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(width: 30, height: 30, child: CropImage(slug: slug, category: repo.cropCategory(slug))),
                ),
                label: repo.cropNames(slug).of(context),
                selected: picked.contains(slug),
                onTap: () => onToggle(slug),
              ),
          ],
        ),
      ],
    );
  }
}

/// 1.7 + 1.8: the mascot builds the plan on screen, then asks for
/// notifications with the reason — after the first task is visible.
class _PlanStep extends StatelessWidget {
  const _PlanStep({required this.ready, required this.region, required this.frost, required this.matches, required this.firstTask, required this.onDone, required this.onLater});
  final bool ready;
  final String region;
  final FrostProfile frost;
  final int matches;
  final String? firstTask;
  final VoidCallback onDone;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Mascot(ready ? MascotPose.celebrating : MascotPose.thinking, size: 96),
            const SizedBox(height: 24),
            Text(ready ? 'Your plan is ready' : 'Creating your growing plan…', style: AppText.display(context)),
            const SizedBox(height: 16),
            _Line(done: true, text: 'Frost dates for $region: last ${frost.lastFrost.substring(5)}, first ${frost.firstFrost.substring(5)}'),
            _Line(done: ready, text: ready ? '$matches crops fit your space this month' : 'Matching crops to your space…'),
            _Line(done: ready, text: ready ? (firstTask == null ? 'First task lands as soon as a window opens' : 'First task: $firstTask') : 'Finding your first task…'),
            const Spacer(),
            if (ready) ...[
              Text(Str.remindBlurb.of(context),
                  style: AppText.bodyMuted(context)),
              const SizedBox(height: 12),
              PrimaryButton(label: Str.remindMe.of(context), icon: PhosphorIcons.bell, onPressed: onDone),
              const SizedBox(height: 8),
              SecondaryButton(label: Str.maybeLater.of(context), onPressed: onLater),
            ] else
              Center(child: CircularProgressIndicator(color: AppColors.sprout)),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.done, required this.text});
  final bool done;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(done ? PhosphorIcons.checkCircle : PhosphorIcons.circle, color: done ? AppColors.sprout : AppColors.hairline, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.body(context))),
        ]),
      );
}
