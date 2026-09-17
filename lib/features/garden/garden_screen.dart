/// My Garden — segmented Planning / Growing / Reminders / Harvest (GrowIt's My
/// Garden pattern, plus our Harvest tracker). Planning = plants with no
/// plantedOn; Growing = plants under way; Reminders = this-week tasks with
/// weather hints; Harvest = the €-value tracker.
library;

import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';
import '../../design/icons.dart';
import '../../design/motion.dart';

import '../../db/database.dart';
import '../../design/colors.dart';
import '../../design/mascot.dart';
import '../../design/components.dart';
import '../../design/crop_image.dart';
import '../../design/typography.dart';
import '../../design/widgets.dart';
import '../harvest/harvest_screen.dart';
import '../this_week/this_week_screen.dart';
import 'garden_repository.dart';
import 'plant_detail_screen.dart';
import 'season_path_view.dart';
import '../repository_scope.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  int _tab = 1; // default to Growing

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Str.myGarden.of(context), style: AppText.kicker(context)),
                          const SizedBox(height: 2),
                          Text.rich(TextSpan(
                            style: AppText.display(context),
                            children: [
                              TextSpan(
                                  text: '${repo.regionName.split(' ').first} '),
                              TextSpan(
                                  text: 'plot',
                                  style: TextStyle(color: AppColors.sprout)),
                            ],
                          )),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(PhosphorIcons.slidersHorizontal, color: AppColors.muted),
                      tooltip: 'Edit garden',
                      onPressed: () => _editGarden(context, repo),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SegmentedTabs(
                  labels: [
                Str.planning.of(context),
                Str.growing.of(context),
                Str.reminders.of(context),
                Str.harvest.of(context),
              ],
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _PlantList(repo: repo, planning: true),
                _PlantList(repo: repo, planning: false),
                const ThisWeekScreen(embedded: true),
                const HarvestScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editGarden(BuildContext context, GardenRepository repo) async {
    final gardens = await repo.gardens();
    if (gardens.isEmpty || !context.mounted) return;
    await showAppSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (_) => _EditGardenSheet(garden: gardens.first),
    );
    if (mounted) setState(() {});
  }
}

class _PlantList extends StatelessWidget {
  const _PlantList({required this.repo, required this.planning});
  final GardenRepository repo;
  final bool planning;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GardenPlantRow>>(
      future: planning ? repo.planningPlants() : repo.growingPlants(),
      builder: (context, snap) {
        final plants = snap.data ?? const [];
        if (plants.isEmpty) {
          if (!planning) return _Empty(planning: planning);
          // The season path covers growing plants too, so it stays visible.
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [const SeasonPathView(), const SizedBox(height: 18), _Empty(planning: true)],
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (planning) ...[const SeasonPathView(), const SizedBox(height: 18), SectionHeader('Planned')],
            for (final p in plants)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey(p.id),
                  direction: DismissDirection.endToStart,
                  background: _swipeToRemoveBackground(context),
                  confirmDismiss: (_) => _confirmRemove(
                      context, repo.cropName(p.cropSlug)),
                  onDismissed: (_) => repo.removePlant(p.id),
                  child: AppCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlantDetailScreen(plantId: p.id))),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: CropImage(
                              slug: p.cropSlug,
                              category: repo.cropCategory(p.cropSlug)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(repo.cropName(p.cropSlug),
                                style: AppText.heading(context)),
                            Text(
                              p.potLitres != null
                                  ? Str.potLitres(p.potLitres!).of(context)
                                  : 'in ground',
                              style: AppText.caption(context),
                            ),
                            if (!planning) _HarvestCountdown(plant: p),
                            if (planning) _PlantIn(cropSlug: p.cropSlug),
                          ],
                        ),
                      ),
                      if (planning)
                        SizedBox(
                          height: 34,
                          child: TextButton(
                            onPressed: () => repo.startGrowing(p.id),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.sprout),
                            child: Text(Str.start.of(context), style: AppText.label(context, color: AppColors.sprout)),
                          ),
                        )
                      else
                        Icon(PhosphorIcons.caretRight, color: AppColors.muted),
                    ],
                  ),
                ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Widget _swipeToRemoveBackground(BuildContext context) => Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.warn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.trash, color: AppColors.warn),
          const SizedBox(width: 6),
          Text(Str.remove.of(context), style: AppText.label(context, color: AppColors.warn)),
        ],
      ),
    );

Future<bool?> _confirmRemove(BuildContext context, String name) => showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(Str.removeAsk(name).of(context), style: AppText.title(context)),
        content: Text(
          'This takes $name out of your garden. Logged harvests stay in your '
          'season history.',
          style: AppText.bodyMuted(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Str.cancel.of(context)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warn),
            onPressed: () => Navigator.pop(context, true),
            child: Text(Str.remove.of(context)),
          ),
        ],
      ),
    );

/// Personalize the garden — rename it, change the growing situation, adjust sun.
class _EditGardenSheet extends StatefulWidget {
  const _EditGardenSheet({required this.garden});
  final GardenRow garden;

  @override
  State<_EditGardenSheet> createState() => _EditGardenSheetState();
}

class _EditGardenSheetState extends State<_EditGardenSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.garden.name);
  late GardenKind _kind = widget.garden.kind;
  late double _sun = (widget.garden.sunHours ?? 6).toDouble();

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Str.editGarden.of(context), style: AppText.title(context)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            style: AppText.body(context),
            decoration: InputDecoration(labelText: Str.gardenName.of(context)),
          ),
          const SizedBox(height: 16),
          Text(Str.growingSituation.of(context), style: AppText.label(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final k in GardenKind.values)
                ChoiceChip(
                  label: Text('${gardenKindEmoji(k)}  ${gardenKindLabel(k)}'),
                  selected: _kind == k,
                  selectedColor: AppColors.sprout.withValues(alpha: 0.18),
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(Str.sunHours(_sun.round()).of(context),
              style: AppText.label(context)),
          Slider(
            value: _sun,
            min: 0,
            max: 12,
            divisions: 12,
            activeColor: AppColors.sprout,
            label: '${_sun.round()}h',
            onChanged: (s) => setState(() => _sun = s),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: Str.saveChanges.of(context),
            onPressed: () async {
              await repo.updateGarden(
                widget.garden.id,
                name: _name.text.trim().isEmpty ? null : _name.text.trim(),
                kind: _kind,
                sunHours: _sun.round(),
              );
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.planning});
  final bool planning;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Base 8.16: a 96 illustration, a heading, two lines, one pill.
              Mascot(planning ? MascotPose.thinking : MascotPose.holdingSeedling,
                  size: 96),
              const SizedBox(height: 16),
              Text((planning ? Str.nothingPlannedYet : Str.nothingGrowingYet).of(context),
                  style: AppText.heading(context)),
              const SizedBox(height: 6),
              Text(
                planning
                    ? 'Tap "Plan to grow" on any crop to add it here.'
                    : 'Tap "Growing it" on a crop, or start a planned one.',
                style: AppText.bodyMuted(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _HarvestCountdown extends StatelessWidget {
  const _HarvestCountdown({required this.plant});
  final GardenPlantRow plant;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<int?>(
      future: repo.daysUntilHarvest(plant),
      builder: (context, snap) {
        final days = snap.data;
        if (days == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Icon(PhosphorIcons.leaf, size: 13, color: AppColors.clay),
            const SizedBox(width: 4),
            Text(
              (days > 0 ? Str.harvestInDays(days) : Str.readyToHarvest).of(context),
              style: AppText.caption(context, color: AppColors.clay),
            ),
          ]),
        );
      },
    );
  }
}

const _monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// GrowIt 5.2 "Plant in: Mar, Apr, May" — from the engine, for this region.
class _PlantIn extends StatelessWidget {
  const _PlantIn({required this.cropSlug});
  final String cropSlug;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final crop = repo.cropBySlug(cropSlug);
    if (crop == null) return const SizedBox.shrink();
    final months = repo.plantMonths(crop);
    if (months.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(Str.plantIn(months.map((m) => _monthAbbr[m - 1]).join(', ')).of(context),
          style: AppText.caption(context, color: AppColors.sprout)),
    );
  }
}
