/// Crop detail — GrowIt-parity depth, our data. Hero → jump-nav chips → stacked
/// sections: Planting calendar · Growth timeline · Difficulty · Suitable location
/// · Soil prep · How-tos · Good neighbours · Benefits · FAQ. Dual "Plan to grow"
/// / "Growing it" CTA. Sections with real data are computed from the engine;
/// editorial ones (soil/how-tos/benefits/FAQ) use prototype copy to refine later.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/companions.dart';
import '../../data/crop_content.dart';
import '../../data/crop_derived.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/crop_image.dart';
import '../../design/typography.dart';
import '../../design/widgets.dart';
import '../../timing/dates.dart';
import '../../timing/types.dart';
import '../repository_scope.dart';
import 'planting_calendar_bar.dart';

class CropDetailScreen extends StatefulWidget {
  const CropDetailScreen({super.key, required this.crop});
  final Crop crop;

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  final _scroll = ScrollController();
  final _keys = <String, GlobalKey>{
    for (final s in _sections) s: GlobalKey(),
  };

  static const _sections = [
    'Calendar', 'Timeline', 'Difficulty', 'Location',
    'Soil', 'How-tos', 'Neighbours', 'Benefits', 'FAQ',
  ];
  // Section id → jump-nav chip label (kept in sync with the sections below).

  void _jump(String s) {
    final ctx = _keys[s]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0.05);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          ListView(
            controller: _scroll,
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 240,
                child: CropImage(slug: crop.slug, category: crop.category),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CategoryDot(crop.category, size: 12),
                      const SizedBox(width: 8),
                      Text(crop.category.toUpperCase(), style: AppText.kicker(context)),
                    ]),
                    const SizedBox(height: 6),
                    Text(crop.names.en, style: AppText.display(context)),
                    Text(crop.names.nl, style: AppText.bodyMuted(context)),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (crop.containerOk && crop.minPotLitres != null)
                        Pill(label: '${crop.minPotLitres} L pot', icon: Icons.crop_square),
                      Pill(label: crop.sun, icon: Icons.wb_sunny_outlined),
                      Pill(
                          label: '${crop.harvestDaysMin}–${crop.harvestDaysMax} days',
                          icon: Icons.schedule),
                      Pill(label: difficultyLabel(difficultyOf(crop)), icon: Icons.bar_chart),
                    ]),
                  ],
                ),
              ),
              _NavChips(sections: _sections, onTap: _jump),
              _section('Calendar', 'Planting calendar', _Calendar(crop: crop)),
              _section('Timeline', 'Growth timeline', _Timeline(crop: crop)),
              _section('Difficulty', 'Difficulty',
                  Center(child: DifficultyGauge(difficulty: difficultyOf(crop)))),
              _section('Location', 'Suitable location', _Location(crop: crop)),
              _section('Soil', 'Soil prep', _Soil(crop: crop)),
              _section('How-tos', 'How-tos', _HowTos(crop: crop)),
              _section('Neighbours', 'Neighbours', _Neighbours(slug: crop.slug)),
              _section('Benefits', 'Why grow it', _Benefits(crop: crop)),
              _section('FAQ', 'FAQ', _Faqs(crop: crop)),
              if (crop.sources.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text('Sources: ${crop.sources.join(' · ')}',
                      style: AppText.caption(context)),
                ),
              const SizedBox(height: 40),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _CircleBack(),
          ),
        ],
      ),
      bottomNavigationBar: _Cta(crop: crop),
    );
  }

  Widget _section(String id, String title, Widget child) => Padding(
        key: _keys[id],
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SectionHeader(title), child],
        ),
      );
}

class _NavChips extends StatelessWidget {
  const _NavChips({required this.sections, required this.onTap});
  final List<String> sections;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => onTap(sections[i]),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border, width: 1.6),
            ),
            child: Text(sections[i], style: AppText.label(context)),
          ),
        ),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final m = crop.methods.first;
    final anchor = m.anchor == FrostAnchor.lastFrost ? 'last frost' : 'first frost';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlantingCalendarBar(crop: crop, frost: repo.frost, today: repo.today),
        const SizedBox(height: 12),
        Text('These dates are frost-relative (anchored to $anchor for '
            '${repo.regionName}) — so they shift with your region, not a fixed calendar.',
            style: AppText.bodyMuted(context)),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final stages = timelineStages(crop);
    final dated = growthTimeline(crop, repo.frost);
    final fmt = DateFormat('d MMM');
    final harvestDate = dated.isNotEmpty ? dated.last.date : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal day-staged strip (GrowIt-style): day range + icon + label.
        Row(
          children: [
            for (var i = 0; i < stages.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Text(stages[i].dayRange, style: AppText.caption(context)),
                    const SizedBox(height: 6),
                    Container(
                      height: 2,
                      color: AppColors.hairline,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    Text(stages[i].emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(stages[i].label, style: AppText.label(context)),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (harvestDate != null)
          Text('At ${repo.regionName}, your first harvest lands around '
              '${fmt.format(parseIso(harvestDate))} — computed from the region\'s '
              'frost dates, not a fixed calendar.',
              style: AppText.bodyMuted(context)),
      ],
    );
  }
}

class _Location extends StatelessWidget {
  const _Location({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final fmt = DateFormat('d MMM');
    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Icon(icon, size: 20, color: AppColors.sprout),
            const SizedBox(width: 12),
            Text(label, style: AppText.bodyMuted(context)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(value,
                    style: AppText.label(context), textAlign: TextAlign.right)),
          ]),
        );
    return Column(children: [
      row(Icons.place_outlined, 'Region', repo.regionName),
      row(Icons.ac_unit, 'Last frost', fmt.format(parseIso(repo.frost.lastFrost))),
      row(Icons.local_fire_department_outlined, 'First frost',
          fmt.format(parseIso(repo.frost.firstFrost))),
      row(Icons.wb_sunny_outlined, 'Preferred sun', crop.sun),
      if (crop.minPotLitres != null)
        row(Icons.crop_square, 'Min pot size', '${crop.minPotLitres} L'),
      row(Icons.check_circle_outline, 'Container-friendly',
          crop.containerOk ? 'Yes' : 'No'),
    ]);
  }
}

class _HowTos extends StatelessWidget {
  const _HowTos({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final stage in howTos(crop))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(stage.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(stage.title, style: AppText.heading(context)),
                  ]),
                  const SizedBox(height: 8),
                  for (final (label, value) in stage.rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 108,
                              child: Text(label, style: AppText.bodyMuted(context))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(value, style: AppText.label(context))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Neighbours extends StatelessWidget {
  const _Neighbours({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    final good = companionsOf(slug);
    final bad = antagonistsOf(slug);
    if (good.isEmpty && bad.isEmpty) {
      return Text('No companion data yet.', style: AppText.bodyMuted(context));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (good.isNotEmpty) ...[
          _NeighbourRow(
              label: 'Good neighbours', slugs: good, color: AppColors.sprout),
          const SizedBox(height: 14),
        ],
        if (bad.isNotEmpty)
          _NeighbourRow(label: 'Bad neighbours', slugs: bad, color: AppColors.warn),
      ],
    );
  }
}

class _NeighbourRow extends StatelessWidget {
  const _NeighbourRow(
      {required this.label, required this.slugs, required this.color});
  final String label;
  final List<String> slugs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: AppText.label(context)),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: slugs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 72,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: CropImage(
                          slug: slugs[i], category: repo.cropCategory(slugs[i])),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(repo.cropName(slugs[i]),
                      style: AppText.caption(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Soil extends StatelessWidget {
  const _Soil({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    Widget factRow(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 20, color: AppColors.sprout),
            const SizedBox(width: 12),
            SizedBox(width: 72, child: Text(label, style: AppText.bodyMuted(context))),
            Expanded(child: Text(value, style: AppText.label(context))),
          ]),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        factRow(Icons.science_outlined, 'Soil pH', soilPh(crop)),
        factRow(Icons.grass, 'Soil type', soilType(crop)),
        const SizedBox(height: 6),
        Text(soilPrep(crop), style: AppText.body(context)),
      ],
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(benefits(crop), style: AppText.body(context)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              for (final n in nutrition(crop))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Expanded(child: Text(n.label, style: AppText.body(context))),
                    Text(n.value, style: AppText.label(context)),
                    if (n.percent != null) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 44,
                        child: Text(n.percent!,
                            textAlign: TextAlign.right,
                            style: AppText.caption(context, color: AppColors.sprout)),
                      ),
                    ] else
                      const SizedBox(width: 54),
                  ]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Faqs extends StatelessWidget {
  const _Faqs({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final f in faqs(crop))
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 10),
              title: Text(f.q, style: AppText.label(context)),
              iconColor: AppColors.sprout,
              collapsedIconColor: AppColors.muted,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(f.a, style: AppText.bodyMuted(context)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CircleBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: Neo.borderWidth),
            boxShadow: Neo.shadowSm,
          ),
          padding: const EdgeInsets.all(7),
          child: const Icon(Icons.arrow_back, color: AppColors.ink, size: 20),
        ),
      );
}

class _Cta extends StatelessWidget {
  const _Cta({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    Future<void> add({required bool growing}) async {
      final gardens = await repo.gardens();
      if (gardens.isEmpty) return;
      await repo.addPlant(
        gardenId: gardens.first.id,
        cropSlug: crop.slug,
        potLitres: crop.minPotLitres?.toInt(),
        plantedOn: growing ? repo.today : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(growing
              ? '${crop.names.en} added to Growing 🌱'
              : '${crop.names.en} added to Planning'),
        ));
        Navigator.of(context).pop();
      }
    }

    return Container(
      color: AppColors.paper,
      padding: EdgeInsets.fromLTRB(
          20, 10, 20, 10 + MediaQuery.of(context).padding.bottom),
      child: Row(children: [
        Expanded(
            child: SecondaryButton(
                label: 'Plan to grow', onPressed: () => add(growing: false))),
        const SizedBox(width: 10),
        Expanded(
            child: PrimaryButton(
                label: 'Growing it', icon: Icons.eco, onPressed: () => add(growing: true))),
      ]),
    );
  }
}
