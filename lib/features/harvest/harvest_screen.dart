/// F7 — Harvest: the season value tracker. A hero tally ("you've grown €142 this
/// season") that turns invisible effort into a number, plus the harvest log and
/// a shareable summary card (share wiring comes later).
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../repository_scope.dart';
import '../garden/garden_repository.dart';

class HarvestScreen extends StatelessWidget {
  const HarvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<List<HarvestRow>>(
      future: repo.harvests(),
      builder: (context, snap) {
        final rows = snap.data ?? const [];
        final total = rows.fold<double>(0, (s, r) => s + r.valueEuros);
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text('Harvest', style: AppText.kicker(context)),
              const SizedBox(height: 10),
              _HeroCard(total: total, count: rows.length),
              const SizedBox(height: 24),
              if (rows.isEmpty)
                _Empty()
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.total, required this.count});
  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final euro = NumberFormat.currency(locale: 'nl_NL', symbol: '€', decimalDigits: 2);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: Neo.box(color: AppColors.clay),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOU\'VE HARVESTED',
              style: AppText.kicker(context, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '$count ${count == 1 ? 'time' : 'times'}',
            style: AppText.display(context, color: Colors.white).copyWith(fontSize: 44),
          ),
          const SizedBox(height: 4),
          Text(
            total > 0
                ? 'this season · ~${euro.format(total)} of veg grown'
                : 'this season',
            style: AppText.body(context, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.ios_share, size: 16, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Text('Share your season',
                  style: AppText.label(context, color: Colors.white)),
            ],
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
    final euro = NumberFormat.currency(locale: 'nl_NL', symbol: '€', decimalDigits: 2);
    return AppCard(
      child: Row(
        children: [
          Text('🧺', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(repo.cropName(row.cropSlug), style: AppText.heading(context)),
                Text(
                  '${row.amount} · ${DateFormat('d MMM').format(parseIso(row.harvestedOn))}',
                  style: AppText.caption(context),
                ),
              ],
            ),
          ),
          if (row.valueEuros > 0)
            Text(euro.format(row.valueEuros),
                style: AppText.label(context, color: AppColors.clay)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Text('🧺', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text('No harvests logged yet', style: AppText.title(context)),
            const SizedBox(height: 6),
            Text('Open a plant and tap "Log harvest" to start counting.',
                style: AppText.bodyMuted(context), textAlign: TextAlign.center),
          ],
        ),
      );
}
