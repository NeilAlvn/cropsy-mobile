/// F3 — Onboarding / setup: region (→ frost) → garden type + sun → pick starter
/// plants → creates the real garden + plants and drops into the app. A "skip"
/// path seeds a ready demo garden so any screen can be reached fast.
library;

import 'package:flutter/material.dart';

import '../../data/frost_presets.dart';
import '../../data/seed.dart';
import '../../db/database.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../repository_scope.dart';

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

  void _next() {
    if (_page < 3) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _Welcome(onSkip: _skip),
                  _RegionStep(
                    selected: _region,
                    onSelect: (r) => setState(() => _region = r),
                  ),
                  _KindStep(
                    kind: _kind,
                    sun: _sun,
                    onKind: (k) => setState(() => _kind = k),
                    onSun: (s) => setState(() => _sun = s),
                  ),
                  _PlantsStep(
                    picked: _picked,
                    onToggle: (slug) => setState(() {
                      _picked.contains(slug)
                          ? _picked.remove(slug)
                          : _picked.add(slug);
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: PrimaryButton(
                label: _page == 3 ? 'Start growing' : 'Continue',
                onPressed: _page == 3 && _picked.isEmpty ? null : _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onSkip});
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Text('🌱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text.rich(TextSpan(
            style: AppText.display(context).copyWith(fontSize: 38),
            children: const [
              TextSpan(text: 'Know what to do\n'),
              TextSpan(
                  text: 'this week',
                  style: TextStyle(color: AppColors.sprout)),
              TextSpan(text: ' in your garden.'),
            ],
          )),
          const SizedBox(height: 12),
          Text(
            'Planting dates and reminders tuned to Dutch & EU weather — '
            'built for balconies and containers.',
            style: AppText.bodyMuted(context),
          ),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: onSkip,
              child: Text('Skip — explore a demo garden',
                  style: AppText.label(context, color: AppColors.muted)),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(24),
      children: [
        Text('Where do you grow?', style: AppText.display(context)),
        const SizedBox(height: 6),
        Text('This sets your frost dates — the backbone of every planting date.',
            style: AppText.bodyMuted(context)),
        const SizedBox(height: 20),
        for (final r in frostRegions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => onSelect(r),
              child: Row(
                children: [
                  Expanded(child: Text(r.name, style: AppText.heading(context))),
                  Icon(
                    r.name == selected.name
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: r.name == selected.name
                        ? AppColors.sprout
                        : AppColors.hairline,
                  ),
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Your growing space', style: AppText.display(context)),
        const SizedBox(height: 20),
        for (final k in GardenKind.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => onKind(k),
              child: Row(
                children: [
                  Text(gardenKindEmoji(k), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(gardenKindLabel(k),
                          style: AppText.heading(context))),
                  Icon(
                    kind == k
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: kind == k ? AppColors.sprout : AppColors.hairline,
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(24),
      children: [
        Text('What will you grow?', style: AppText.display(context)),
        const SizedBox(height: 6),
        Text('Pick a few to start — you can add more anytime.',
            style: AppText.bodyMuted(context)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final slug in options)
              GestureDetector(
                onTap: () => onToggle(slug),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: picked.contains(slug)
                        ? AppColors.sprout
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: picked.contains(slug)
                          ? AppColors.sprout
                          : AppColors.hairline,
                    ),
                  ),
                  child: Text(
                    repo.cropName(slug),
                    style: AppText.label(
                      context,
                      color: picked.contains(slug) ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
