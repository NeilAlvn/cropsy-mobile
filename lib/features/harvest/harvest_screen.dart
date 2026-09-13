/// Harvest (PRD 7.5): the season payoff — yield tally in kg / pieces and the
/// "money saved" estimate from the price table (shown only for priced crops;
/// nothing is invented while prices.json is empty).
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/mascot.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../garden/garden_repository.dart';
import '../repository_scope.dart';

class HarvestScreen extends StatelessWidget {
  const HarvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<(List<HarvestRow>, ({double euros, double kg, double pcs, int unpriced}))>(
      future: _load(repo),
      builder: (context, snap) {
        final rows = snap.data?.$1 ?? const <HarvestRow>[];
        final tally = snap.data?.$2;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text('Harvest', style: AppText.kicker(context)),
              const SizedBox(height: 10),
              if (tally != null) _HeroCard(tally: tally, count: rows.length),
              const SizedBox(height: 24),
              if (rows.isEmpty)
                const MascotSays(pose: MascotPose.holdingSeedling, text: 'Nothing picked yet. Log a harvest from a plant and the tally starts.')
              else ...[
                SectionHeader('Your harvests'),
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HarvestTile(row: r, repo: repo),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

Future<(List<HarvestRow>, ({double euros, double kg, double pcs, int unpriced}))> _load(GardenRepository repo) async =>
    (await repo.harvests(), await repo.seasonTally());

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.tally, required this.count});
  final ({double euros, double kg, double pcs, int unpriced}) tally;
  final int count;

  String _n(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (tally.kg > 0) '${_n(tally.kg)} kg',
      if (tally.pcs > 0) '${_n(tally.pcs)} pieces',
    ];
    return Container(
      decoration: Neo.box(color: AppColors.clay),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIS SEASON', style: AppText.kicker(context, color: Colors.white70)),
          const SizedBox(height: 6),
          Text(parts.isEmpty ? 'Nothing yet' : parts.join(' · '), style: AppText.display(context, color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            tally.euros > 0
                ? '≈ €${tally.euros.toStringAsFixed(2)} saved at NL supermarket prices'
                    '${tally.unpriced > 0 ? ' · ${tally.unpriced} unpriced' : ''}'
                : '$count harvest${count == 1 ? '' : 's'} logged · price table coming with the content update',
            style: AppText.body(context, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HarvestTile extends StatelessWidget {
  const _HarvestTile({required this.row, required this.repo});
  final HarvestRow row;
  final GardenRepository repo;

  @override
  Widget build(BuildContext context) {
    final value = repo.harvestValue(row);
    return AppCard(
      child: Row(children: [
        CategoryDot(repo.cropCategory(row.cropSlug), size: 12),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${repo.cropName(row.cropSlug)} · ${row.amount}', style: AppText.label(context)),
              Text(DateFormat('EEEE d MMM').format(parseIso(row.harvestedOn)), style: AppText.caption(context)),
            ],
          ),
        ),
        if (value != null) Text('€${value.toStringAsFixed(2)}', style: AppText.label(context, color: AppColors.clay)),
      ]),
    );
  }
}
