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
import '../../design/feedback_row.dart';
import '../../design/mascot.dart';
import '../../design/typography.dart';
import '../../design/widgets.dart';
import '../../timing/dates.dart';
import '../../timing/types.dart';
import '../repository_scope.dart';
import '../paywall/paywall_screen.dart';
import 'add_plant_sheet.dart';
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
    final repo = RepositoryScope.of(context);
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
                    if (crop.draft) const Padding(padding: EdgeInsets.only(top: 4), child: DraftBadge()),
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
              if (repo.content.varietiesOf(crop.slug).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader('Types'),
                      SizedBox(
                        height: 84,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final v in repo.content.varietiesOf(crop.slug))
                              Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: Neo.box(color: AppColors.surface),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.names.en, style: AppText.label(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(v.traits.take(3).join(' · '), style: AppText.caption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const Spacer(),
                                    Text(v.suppliers.isEmpty ? '' : 'at ${v.suppliers.first}', style: AppText.caption(context, color: AppColors.sprout)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              _NavChips(sections: _sections, onTap: _jump),
              _section('Calendar', 'Planting calendar', _Calendar(crop: crop)),
              _section('Timeline', 'Growth timeline', _Timeline(crop: crop)),
              _section('Difficulty', 'Difficulty',
                  Center(child: DifficultyGauge(difficulty: difficultyOf(crop)))),
              _section('Location', 'Suitable location', _Location(crop: crop)),
              _section('Soil', 'Soil prep', const _ContentComing('Soil preparation')),
              _section('How-tos', 'How-tos', _HowTos(crop: crop)),
              _section('Neighbours', 'Neighbours', _Neighbours(slug: crop.slug)),
              _section('Benefits', 'Why grow it', _GuideBenefits(slug: crop.slug)),
              _section('FAQ', 'FAQ', _GuideFaq(slug: crop.slug)),
              if (crop.sources.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text('Sources: ${crop.sources.join(' · ')}',
                      style: AppText.caption(context)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: FeedbackRow(targetKind: 'crop', targetId: crop.slug),
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
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
            '${repo.regionName}) . They shift with your region, not a fixed calendar.',
            style: AppText.bodyMuted(context)),
        const SizedBox(height: 8),
        // 3.3 "Calendar based on" row: frost cell + where the dates came from.
        Wrap(spacing: 8, runSpacing: 6, children: [
          Pill(label: 'Based on: ${repo.regionName}', icon: Icons.place_outlined),
          Pill(
            label: repo.frostSource == 'open-meteo' ? 'KNMI/Open-Meteo climate normals' : 'NL regional preset',
            icon: Icons.thermostat,
          ),
          Pill(label: 'Verified against ${crop.sources.length} NL sources', icon: Icons.verified_outlined),
        ]),
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
              '${fmt.format(parseIso(harvestDate))} , computed from the region\'s '
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
    final minSoil = crop.methods.map((m) => m.minSoilC).whereType<num>().fold<num?>(null, (a, b) => a == null ? b : (b < a ? b : a));
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
      row(Icons.ac_unit, 'Frost tender', crop.frostTender ? 'Yes, wait for last frost' : 'No'),
      if (minSoil != null) row(Icons.device_thermostat, 'Min soil temp', '$minSoil °C'),
      if (crop.minPotLitres != null)
        row(Icons.crop_square, 'Min pot size', '${crop.minPotLitres} L'),
      row(Icons.check_circle_outline, 'Container-friendly',
          crop.containerOk ? 'Yes' : 'No'),
      row(Icons.public, 'NL balcony suitability', crop.containerOk && !crop.frostTender ? 'Great' : crop.containerOk ? 'Good after IJsheiligen' : 'Needs a bed'),
    ]);
  }
}

class _HowTos extends StatelessWidget {
  const _HowTos({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final water = crop.waterCadenceDays;
    final stages = <(String, String, List<(String, String)>)>[
      ('🌱', 'Starting', [
        if (crop.depthMm != null) ('Sow depth', '${crop.depthMm} mm'),
        if (crop.germinationDays != null) ('Germination', '~${crop.germinationDays} days'),
        if (crop.daysToTransplant != null) ('Plant out after', '~${crop.daysToTransplant} days indoors'),
        ('Spacing', '${crop.spacingCm} cm'),
        if (crop.vakPerM2 != null) ('Per 30 cm square', '${crop.vakPerM2}'),
      ]),
      ('💧', 'Care', [
        ('Water (small pot)', 'every ${water?.small ?? 1} day${(water?.small ?? 1) == 1 ? '' : 's'}'),
        ('Water (in ground)', 'every ${water?.ground ?? 4} days'),
        if (crop.feedCadenceDays != null) ('Feed', 'every ${crop.feedCadenceDays} days once established'),
        if (crop.perennial) ('Perennial', 'comes back next year'),
      ]),
      ('🧺', 'Harvest', [
        ('First harvest', '${crop.harvestDaysMin}–${crop.harvestDaysMax} days after planting out'),
      ]),
    ];
    return Column(
      children: [
        for (final (emoji, title, rows) in stages)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(title, style: AppText.heading(context)),
                  ]),
                  const SizedBox(height: 8),
                  for (final (label, value) in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 128, child: Text(label, style: AppText.bodyMuted(context))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(value, style: AppText.label(context))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        _GuideStages(slug: crop.slug),
      ],
    );
  }
}

/// Editorial how-tos per stage from the content snapshot; placeholder until
/// the crop has a guide. Drafts carry the concept badge (beta only).
class _GuideStages extends StatelessWidget {
  const _GuideStages({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    final g = RepositoryScope.of(context).content.guideFor(slug);
    if (g == null) return const _ContentComing('Step-by-step how-tos per stage');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (g.draft) const Padding(padding: EdgeInsets.only(bottom: 8), child: DraftBadge()),
        for (final st in g.stages)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(st.title, style: AppText.heading(context)),
                const SizedBox(height: 6),
                Text(st.body, style: AppText.body(context)),
              ]),
            ),
          ),
      ],
    );
  }
}

class _GuideFaq extends StatelessWidget {
  const _GuideFaq({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    final g = RepositoryScope.of(context).content.guideFor(slug);
    if (g == null || g.faq.isEmpty) return const _ContentComing('Grower-reviewed FAQ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (g.draft) const Padding(padding: EdgeInsets.only(bottom: 8), child: DraftBadge()),
        for (final f in g.faq)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(f.q, style: AppText.label(context)),
              children: [Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(f.a, style: AppText.body(context)))],
            ),
          ),
      ],
    );
  }
}

class _GuideBenefits extends StatelessWidget {
  const _GuideBenefits({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    final g = RepositoryScope.of(context).content.guideFor(slug);
    if (g == null) return const _ContentComing('Nutrition and benefits (NEVO)');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (g.draft) const Padding(padding: EdgeInsets.only(bottom: 8), child: DraftBadge()),
        Text(g.benefits, style: AppText.body(context)),
        if (g.sources.isNotEmpty) ...[
          const SizedBox(height: 8),
          // Domains only: 18 full URLs are review data, not reading matter.
          Text('Sources: ${g.sources.map((u) => Uri.tryParse(u)?.host.replaceFirst('www.', '') ?? u).toSet().join(' · ')}', style: AppText.caption(context)),
        ],
      ],
    );
  }
}

/// Phase 1 placeholder for editorial sections (PRD 3.2): says so instead of
/// showing generated filler as fact.
class _ContentComing extends StatelessWidget {
  const _ContentComing(this.what);
  final String what;

  @override
  Widget build(BuildContext context) => AppCard(
        child: MascotSays(
          pose: MascotPose.thinking,
          size: 40,
          text: '$what: being written and checked for Dutch gardens. Coming in the content update.',
        ),
      );
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
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Pill(label: 'Draft. The verified matrix lands in the content update', icon: Icons.edit_note, color: AppColors.clay),
        ),
        _NeighboursBody(good: good, bad: bad),
      ],
    );
  }
}

class _NeighboursBody extends StatelessWidget {
  const _NeighboursBody({required this.good, required this.bad});
  final List<String> good;
  final List<String> bad;

  @override
  Widget build(BuildContext context) {
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

class _CircleBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.onInk,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: Neo.borderWidth),
            boxShadow: Neo.shadowSm,
          ),
          padding: const EdgeInsets.all(7),
          child: Icon(Icons.arrow_back, color: AppColors.ink, size: 20),
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
      PlantDetails? details;
      if (growing) {
        if (!context.mounted) return;
        final limit = PurchaseScope.maybeOf(context)?.maxGrowingPlants ?? 6;
        if ((await repo.growingPlants()).length >= limit) {
          if (!context.mounted) return;
          final bought = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const PaywallScreen(), fullscreenDialog: true));
          if (bought != true) return;
        }
        if (!context.mounted) return;
        details = await showAddPlantSheet(context, crop: crop, today: repo.today);
        if (details == null) return;
      }
      await repo.addPlant(
        gardenId: gardens.first.id,
        cropSlug: crop.slug,
        potLitres: growing ? details!.potLitres : crop.minPotLitres?.toInt(),
        plantedOn: details?.plantedOn,
        method: details?.method,
        place: details?.place,
        varietySlug: details?.variety,
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
