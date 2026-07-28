/// F1 — crop detail: the planting calendar for one crop, showing the *why*
/// (frost-relative timing) alongside the concrete dated window for the user's
/// region, plus pot size / sun / harvest time and an "Add to my garden" action.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../../timing/engine.dart';
import '../../timing/types.dart';
import '../repository_scope.dart';

class CropDetailScreen extends StatelessWidget {
  const CropDetailScreen({super.key, required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final windows = scheduleCrop(crop, repo.frost);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: AppColors.paper,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          Row(
            children: [
              CategoryDot(crop.category, size: 14),
              const SizedBox(width: 8),
              Text(crop.category.toUpperCase(), style: AppText.kicker(context)),
            ],
          ),
          const SizedBox(height: 6),
          Text(crop.names.en, style: AppText.display(context)),
          Text(crop.names.nl, style: AppText.bodyMuted(context)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (crop.containerOk && crop.minPotLitres != null)
                Pill(label: '${crop.minPotLitres} L pot min', icon: Icons.crop_square),
              Pill(label: crop.sun, icon: Icons.wb_sunny_outlined),
              Pill(
                label: '${crop.harvestDaysMin}–${crop.harvestDaysMax} days to harvest',
                icon: Icons.schedule,
              ),
              if (crop.containerOk)
                const Pill(label: 'Balcony-friendly', icon: Icons.check),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader('When to plant', trailing: Text(
            'your region',
            style: AppText.caption(context),
          )),
          for (final w in windows) _WindowCard(crop: crop, window: w),
          const SizedBox(height: 20),
          if (crop.sources.isNotEmpty) ...[
            SectionHeader('Sources'),
            Text(crop.sources.join(' · '), style: AppText.caption(context)),
            const SizedBox(height: 24),
          ],
          PrimaryButton(
            label: 'Add to my garden',
            icon: Icons.add,
            onPressed: () async {
              final gardens = await repo.gardens();
              if (gardens.isEmpty) return;
              await repo.addPlant(
                gardenId: gardens.first.id,
                cropSlug: crop.slug,
                potLitres: crop.minPotLitres?.toInt(),
                plantedOn: repo.today,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${crop.names.en} added to your garden')),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _WindowCard extends StatelessWidget {
  const _WindowCard({required this.crop, required this.window});
  final Crop crop;
  final ScheduledWindow window;

  @override
  Widget build(BuildContext context) {
    final method = crop.methods.firstWhere((m) => m.type == window.method);
    final fmt = DateFormat('d MMM');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_methodLabel(window.method), style: AppText.heading(context)),
                const Spacer(),
                Text(
                  '${fmt.format(parseIso(window.start))} – ${fmt.format(parseIso(window.end))}',
                  style: AppText.label(context, color: AppColors.sprout),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_why(method), style: AppText.bodyMuted(context)),
            if (window.minSoilC != null) ...[
              const SizedBox(height: 8),
              Pill(
                label: 'needs soil ≥ ${window.minSoilC}°C',
                icon: Icons.thermostat,
                color: AppColors.frost,
                bg: AppColors.frost.withValues(alpha: 0.12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _methodLabel(MethodType m) => switch (m) {
        MethodType.sowIndoor => 'Start indoors',
        MethodType.sowDirect => 'Sow outdoors',
        MethodType.transplant => 'Plant out',
        MethodType.plant => 'Plant',
      };

  static String _why(CropMethod m) {
    final anchor = m.anchor == FrostAnchor.lastFrost ? 'last frost' : 'first frost';
    final w = m.startWeeks.abs();
    final wk = w == 1 ? '1 week' : '$w weeks';
    if (m.startWeeks < 0) return 'About $wk before $anchor — that\'s why the date shifts with your region.';
    if (m.startWeeks > 0) return 'About $wk after $anchor, once conditions are safe.';
    return 'Right around $anchor.';
  }
}
