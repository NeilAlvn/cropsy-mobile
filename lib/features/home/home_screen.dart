/// Home — the catalogue browse (GrowIt-shaped): region header, search + Add
/// plant, a mock premium banner, and "What to grow in [month]" with filter chips
/// and a photo-card grid. Our differentiator: the recommendations come from the
/// real frost-relative engine for the user's region.
library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/crop_image.dart';
import '../../design/mascot.dart';
import '../../design/typography.dart';
import '../../design/widgets.dart';
import '../../timing/dates.dart';
import '../../timing/replan.dart';
import '../../timing/types.dart';
import '../../timing/weather_adjust.dart';
import '../garden/garden_repository.dart';
import '../garden/plant_detail_screen.dart';
import '../grow/crop_detail_screen.dart';
import '../location/location_sheet.dart';
import '../paywall/paywall_screen.dart';
import '../settings/settings_screen.dart';
import '../repository_scope.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _month;
  String _filter = 'all';
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Default the month to "today" — read here, not in initState, since it
    // depends on the inherited RepositoryScope.
    _month ??= parseIso(RepositoryScope.of(context).today).month;
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final List<Crop> crops = _query.isNotEmpty
        ? (repo.crops
            .where((c) =>
                c.names.en.toLowerCase().contains(_query.toLowerCase()) ||
                c.names.nl.toLowerCase().contains(_query.toLowerCase()))
            .toList()
          ..sort((a, b) => a.names.en.compareTo(b.names.en)))
        : repo.whatToGrowIn(_month!, filter: _filter);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(region: repo.regionName)),
          SliverToBoxAdapter(child: _SearchRow(onChanged: (q) => setState(() => _query = q))),
          SliverToBoxAdapter(child: _PremiumBanner(onTap: () => _openPaywall(context))),
          if (_query.isEmpty) ...[
            const SliverToBoxAdapter(child: _TodaysCare()),
            const SliverToBoxAdapter(child: _UpcomingHarvest()),
          ],
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: _WhatToGrowHeader(
                month: _month!,
                filter: _filter,
                onMonth: _pickMonth,
                onFilter: (f) => setState(() => _filter = f),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text('${crops.length} results',
                    style: AppText.kicker(context)),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => PhotoCard(
                  crop: crops[i],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CropDetailScreen(crop: crops[i]))),
                ),
                childCount: crops.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPaywall(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen(), fullscreenDialog: true),
      );

  Future<void> _pickMonth() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('What to grow in…', style: AppText.title(context)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 8),
                itemCount: 12,
                itemBuilder: (context, i) {
                  final m = i + 1;
                  return ListTile(
                    title: Text(_months[i], style: AppText.body(context)),
                    trailing: m == _month
                        ? const Icon(Icons.check, color: AppColors.sprout)
                        : null,
                    onTap: () => Navigator.pop(context, m),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _month = picked);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.region});
  final String region;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showLocationPicker(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: AppColors.sprout),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(region,
                          style: AppText.label(context),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.expand_more, size: 18, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.workspace_premium, color: AppColors.sprout),
          const SizedBox(width: 14),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.settings_outlined, color: AppColors.muted),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppText.body(context),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search vegetables',
                hintStyle: AppText.bodyMuted(context),
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.border, width: Neo.borderWidth),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.sprout, width: Neo.borderWidth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: Neo.box(color: AppColors.ink),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Try Cropsy Premium free for 7 days',
                    style: AppText.label(context, color: Colors.white)),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatToGrowHeader extends StatelessWidget {
  const _WhatToGrowHeader({
    required this.month,
    required this.filter,
    required this.onMonth,
    required this.onFilter,
  });
  final int month;
  final String filter;
  final VoidCallback onMonth;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Text('What to grow in ', style: AppText.title(context)),
                GestureDetector(
                  onTap: onMonth,
                  child: Row(
                    children: [
                      Text(_months[month - 1],
                          style: AppText.title(context, color: AppColors.sprout)),
                      const Icon(Icons.arrow_drop_down, color: AppColors.sprout),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilterChipsRow(
            options: const [
              ('all', 'All'),
              ('indoors', 'Start indoors'),
              ('outside', 'Plant outside'),
              ('easy', 'Easy'),
            ],
            selected: filter,
            onSelect: onFilter,
          ),
        ],
      ),
    );
  }
}

/// 2.3 — Today's care: the weather card says what it changed, then today's
/// tasks with checkboxes. Nothing to do → the mascot says so.
class _TodaysCare extends StatelessWidget {
  const _TodaysCare();

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<List<ThisWeekItem>>(
      future: repo.thisWeek(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final today = snap.data!.where((i) => i.due.compareTo(repo.today) <= 0).toList();
        final open = today.where((i) => !i.completed).length;
        final skipped = today.where((i) => i.hint?.action == AdjustAction.skip).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's care ($open)", style: AppText.title(context)),
              const SizedBox(height: 10),
              AppCard(
                child: MascotSays(
                  pose: skipped.isNotEmpty ? MascotPose.rain : (open == 0 ? MascotPose.sleeping : MascotPose.sun),
                  size: 44,
                  text: skipped.isNotEmpty
                      ? skipped.first.hint!.reason.en
                      : open == 0
                          ? 'Nothing to do today. Enjoy it.'
                          : '$open thing${open == 1 ? '' : 's'} to do today.',
                ),
              ),
              const SizedBox(height: 8),
              for (final item in today.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => repo.setTaskCompleted(item.taskId, !item.completed),
                    child: Row(children: [
                      Icon(item.completed ? Icons.check_circle : Icons.circle_outlined,
                          color: item.completed ? AppColors.done : AppColors.hairline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('${kindLabel(item.kind)} · ${item.cropName}',
                            style: AppText.label(context, color: item.completed ? AppColors.muted : AppColors.ink)),
                      ),
                      if (item.hint != null) WeatherHintBadge(item.hint!),
                    ]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 2.4 — Upcoming harvest: hero cards with the harvest window from the path.
class _UpcomingHarvest extends StatelessWidget {
  const _UpcomingHarvest();

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<List<({GardenPlantRow plant, PathNode harvest})>>(
      future: repo.upcomingHarvests(),
      builder: (context, snap) {
        final rows = snap.data ?? const [];
        if (rows.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upcoming harvest (${rows.length})', style: AppText.title(context)),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    final h = r.harvest;
                    final fmt = DateFormat('d MMM');
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: r.plant.id)),
                      ),
                      child: Container(
                        width: 200,
                        decoration: Neo.box(color: AppColors.surface),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 84,
                              width: double.infinity,
                              child: CropImage(slug: r.plant.cropSlug, category: repo.cropCategory(r.plant.cropSlug)),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(repo.cropName(r.plant.cropSlug), style: AppText.label(context)),
                                  Text(
                                    '${fmt.format(parseIso(h.due))} – ${fmt.format(parseIso(h.until ?? h.due))}',
                                    style: AppText.caption(context, color: AppColors.clay),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
