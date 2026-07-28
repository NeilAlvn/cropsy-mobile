/// My Garden — segmented Planning / Growing / Reminders / Harvest (GrowIt's My
/// Garden pattern, plus our Harvest tracker). Planning = plants with no
/// plantedOn; Growing = plants under way; Reminders = this-week tasks with
/// weather hints; Harvest = the €-value tracker.
library;

import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/crop_image.dart';
import '../../design/typography.dart';
import '../../design/widgets.dart';
import '../harvest/harvest_screen.dart';
import '../this_week/this_week_screen.dart';
import 'garden_repository.dart';
import 'plant_detail_screen.dart';
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
                Text('My garden', style: AppText.kicker(context)),
                const SizedBox(height: 2),
                Text.rich(TextSpan(
                  style: AppText.display(context),
                  children: [
                    TextSpan(text: '${repo.regionName.split(' ').first} '),
                    const TextSpan(
                        text: 'plot', style: TextStyle(color: AppColors.sprout)),
                  ],
                )),
                const SizedBox(height: 14),
                SegmentedTabs(
                  labels: const ['Planning', 'Growing', 'Reminders', 'Harvest'],
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
          return _Empty(planning: planning);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            for (final p in plants)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
                                  ? '${p.potLitres} L pot'
                                  : 'in ground',
                              style: AppText.caption(context),
                            ),
                            if (!planning && repo.daysUntilHarvest(p) != null) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.eco, size: 13, color: AppColors.clay),
                                const SizedBox(width: 4),
                                Text(
                                  repo.daysUntilHarvest(p)! > 0
                                      ? 'Harvest in ${repo.daysUntilHarvest(p)} days'
                                      : 'Ready to harvest',
                                  style: AppText.caption(context, color: AppColors.clay),
                                ),
                              ]),
                            ],
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
                            child: Text('Start', style: AppText.label(context, color: AppColors.sprout)),
                          ),
                        )
                      else
                        const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
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
              Text(planning ? '📋' : '🌱', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(planning ? 'Nothing planned yet' : 'Nothing growing yet',
                  style: AppText.title(context)),
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
