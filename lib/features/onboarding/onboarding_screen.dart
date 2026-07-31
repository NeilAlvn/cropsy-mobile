/// F3 — Onboarding / setup: region (→ frost) → garden type + sun → pick starter
/// plants → creates the real garden + plants and drops into the app. A "skip"
/// path seeds a ready demo garden so any screen can be reached fast.
library;

import 'package:flutter/material.dart';

import '../../data/frost_presets.dart';
import '../../data/seed.dart';
import '../../db/database.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/crop_image.dart';
import '../../design/typography.dart';
import '../repository_scope.dart';
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

  FrostRegion _region = defaultRegion;
  GardenKind _kind = GardenKind.balcony;
  double _sun = 6;
  late final Set<String> _picked = {...starterCrops.keys};

  static const _pageCount = 4;

  static const _pageDuration = Duration(milliseconds: 380);
  static const _pageCurve = Curves.easeInOutCubic;

  void _prev() {
    if (_page > 0) {
      _controller.previousPage(duration: _pageDuration, curve: _pageCurve);
    }
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _controller.nextPage(duration: _pageDuration, curve: _pageCurve);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final repo = RepositoryScope.of(context);
    final gardenId = await repo.createGarden(
      region: _region,
      kind: _kind,
      sunHours: _sun.round(),
      name: gardenKindLabel(_kind),
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
    widget.onDone();
  }

  Future<void> _skip() async {
    await RepositoryScope.of(context).seedDemoGarden();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (p) => setState(() => _page = p),
            children: [
              // 1 · Welcome — still hero (video deferred; swap back to
              // HeroMedia.video once we have a Flow-generated clip).
              HeroPage(
                media: const HeroMedia.image('assets/onboarding/welcome.jpg'),
                kicker: 'CROPSY',
                title: const [
                  TextSpan(text: 'Know what to do\n'),
                  TextSpan(
                      text: 'this week',
                      style: TextStyle(color: AppColors.sprout)),
                  TextSpan(text: ' in your garden.'),
                ],
                subtitle: 'Planting dates and reminders tuned to Dutch & EU '
                    'weather — built for balconies and containers.',
                buttonLabel: 'Get started',
                onNext: _next,
              ),
              // 2 · Where do you grow (location / frost region).
              _SetupPage(
                buttonLabel: 'Continue',
                onNext: _next,
                child: _RegionStep(
                  selected: _region,
                  onSelect: (r) => setState(() => _region = r),
                ),
              ),
              // 3 · Growing space + sun.
              _SetupPage(
                buttonLabel: 'Continue',
                onNext: _next,
                child: _KindStep(
                  kind: _kind,
                  sun: _sun,
                  onKind: (k) => setState(() => _kind = k),
                  onSun: (s) => setState(() => _sun = s),
                ),
              ),
              // 4 · Pick your crops.
              _SetupPage(
                buttonLabel: 'Start growing',
                enabled: _picked.isNotEmpty,
                onNext: _next,
                child: _PlantsStep(
                  picked: _picked,
                  onToggle: (slug) => setState(() {
                    _picked.contains(slug)
                        ? _picked.remove(slug)
                        : _picked.add(slug);
                  }),
                ),
              ),
            ],
          ),
          // Persistent floating header — stays put while pages transition.
          // Left control: Skip on the first frame, Back on the rest.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _FloatingHeader(
                  page: _page,
                  pageCount: _pageCount,
                  onBack: _prev,
                  onSkip: _skip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one persistent onboarding header: a bordered floating bar with a Skip
/// (first frame) / Back (later frames) control and the progress track.
class _FloatingHeader extends StatelessWidget {
  const _FloatingHeader({
    required this.page,
    required this.pageCount,
    required this.onBack,
    required this.onSkip,
  });

  final int page;
  final int pageCount;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final first = page == 0;
    return Container(
      decoration:
          Neo.box(color: AppColors.surface, shadowOverride: Neo.shadowSm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          GestureDetector(
            onTap: first ? onSkip : onBack,
            child: first
                ? Text('Skip', style: AppText.label(context))
                : const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          _ProgressRow(page: page, count: pageCount),
        ],
      ),
    );
  }
}

/// A setup step — clean paper with the form + a bottom action. The header
/// (back/skip + progress) floats above this from the parent, so we leave room
/// for it at the top and never redraw it here.
class _SetupPage extends StatelessWidget {
  const _SetupPage({
    required this.child,
    required this.buttonLabel,
    required this.onNext,
    this.enabled = true,
  });

  final Widget child;
  final String buttonLabel;
  final VoidCallback onNext;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Clearance for the floating header.
          const SizedBox(height: 62),
          Expanded(child: child),
          Padding(
            padding: const EdgeInsets.all(20),
            child: PrimaryButton(
              label: buttonLabel,
              icon: Icons.arrow_forward,
              onPressed: enabled ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered progress dots (shared by hero + setup pages). Fixed-width slots so
/// nothing shifts as you advance — only the fill colour animates.
class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.page, required this.count});
  final int page;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            width: 18,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: i <= page ? AppColors.sprout : AppColors.hairline,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _RegionStep extends StatelessWidget {
  const _RegionStep({required this.selected, required this.onSelect});
  final FrostRegion selected;
  final ValueChanged<FrostRegion> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Where do you grow?', style: AppText.title(context)),
        const SizedBox(height: 6),
        Text('This sets your frost dates — the backbone of every planting date.',
            style: AppText.bodyMuted(context)),
        const SizedBox(height: 14),
        for (final r in frostRegions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectTile(
              icon: Icons.place_outlined,
              label: r.name,
              selected: r.name == selected.name,
              onTap: () => onSelect(r),
            ),
          ),
      ],
    );
  }
}

class _KindStep extends StatelessWidget {
  const _KindStep({
    required this.kind,
    required this.sun,
    required this.onKind,
    required this.onSun,
  });
  final GardenKind kind;
  final double sun;
  final ValueChanged<GardenKind> onKind;
  final ValueChanged<double> onSun;

  static const _icons = {
    GardenKind.balcony: Icons.balcony,
    GardenKind.garden: Icons.yard,
    GardenKind.allotment: Icons.agriculture,
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Your growing space', style: AppText.title(context)),
        const SizedBox(height: 6),
        Text('Where are you growing?', style: AppText.bodyMuted(context)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            for (final k in GardenKind.values)
              _SelectTile(
                icon: _icons[k],
                label: gardenKindLabel(k),
                selected: kind == k,
                onTap: () => onKind(k),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Hours of sun a day: ${sun.round()}h',
            style: AppText.heading(context)),
        Slider(
          value: sun,
          min: 0,
          max: 12,
          divisions: 12,
          activeColor: AppColors.sprout,
          label: '${sun.round()}h',
          onChanged: onSun,
        ),
      ],
    );
  }
}

/// A bordered selection tile: fills green + white text/icon when selected. Pass
/// either an [icon] (recoloured white on select, always visible) or a
/// [leadingWidget] (e.g. a crop photo, left as-is).
class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leadingWidget,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? leadingWidget;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.ink;
    final Widget? leading = icon != null
        ? Icon(icon, size: 22, color: selected ? Colors.white : AppColors.sprout)
        : leadingWidget;
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
            if (leading != null) ...[
              leading,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(label,
                  style: AppText.label(context, color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? Colors.white : AppColors.hairline,
            ),
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
    // Offer a friendly shortlist: the starters + a few more container crops.
    final options = <String>{
      ...starterCrops.keys,
      'chili',
      'cucumber',
      'chives',
      'coriander',
      'beetroot',
    }.toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('What will you grow?', style: AppText.title(context)),
        const SizedBox(height: 6),
        Text('Pick a few to start — add more anytime.',
            style: AppText.bodyMuted(context)),
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
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CropImage(
                        slug: slug, category: repo.cropCategory(slug)),
                  ),
                ),
                label: repo.cropName(slug),
                selected: picked.contains(slug),
                onTap: () => onToggle(slug),
              ),
          ],
        ),
      ],
    );
  }
}
