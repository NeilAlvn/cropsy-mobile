/// Garden tab — the user's plants (F3 result). Tap a plant for its journal (F5)
/// and to log a harvest (F7).
library;

import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../repository_scope.dart';
import 'garden_repository.dart';
import 'plant_detail_screen.dart';

class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<List<GardenRow>>(
      future: repo.gardens(),
      builder: (context, gs) {
        final garden = (gs.data ?? const []).isEmpty ? null : gs.data!.first;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text('My garden', style: AppText.kicker(context)),
              const SizedBox(height: 2),
              Text.rich(TextSpan(
                style: AppText.display(context),
                children: [
                  TextSpan(
                      text: garden == null
                          ? 'Your plants'
                          : '${gardenKindEmoji(garden.kind)} ${garden.name}'),
                ],
              )),
              if (garden != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${gardenKindLabel(garden.kind)}'
                    '${garden.sunHours != null ? ' · ${garden.sunHours}h sun' : ''}',
                    style: AppText.bodyMuted(context),
                  ),
                ),
              const SizedBox(height: 16),
              if (garden == null)
                Text('No garden yet.', style: AppText.bodyMuted(context))
              else
                _PlantList(gardenId: garden.id, repo: repo),
            ],
          ),
        );
      },
    );
  }
}

class _PlantList extends StatelessWidget {
  const _PlantList({required this.gardenId, required this.repo});
  final String gardenId;
  final GardenRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GardenPlantRow>>(
      future: repo.plants(gardenId),
      builder: (context, ps) {
        final plants = ps.data ?? const [];
        if (plants.isEmpty) {
          return Text('Add plants from the Grow tab.',
              style: AppText.bodyMuted(context));
        }
        return Column(
          children: [
            for (final p in plants)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PlantDetailScreen(plantId: p.id),
                  )),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.categoryColor(
                                  repo.cropCategory(p.cropSlug))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CategoryDot(repo.cropCategory(p.cropSlug), size: 14),
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
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            SecondaryButton(
              label: '+ Add a plant',
              onPressed: () {
                DefaultTabController.maybeOf(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Browse the Grow tab to add a plant')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
