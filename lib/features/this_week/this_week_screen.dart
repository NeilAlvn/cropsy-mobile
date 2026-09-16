/// F2 — "This Week": the prioritized task list, the core loop. Base-schedule
/// windows + client-side waterings for `[today, today+7)`, grouped by day, each
/// carrying a weather-aware hint (F4). Tap to complete.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../../timing/weather_adjust.dart' show TaskKind;
import '../garden/garden_repository.dart';
import '../garden/plant_detail_screen.dart';
import '../repository_scope.dart';

class ThisWeekScreen extends StatelessWidget {
  const ThisWeekScreen({super.key, this.embedded = false});

  /// When embedded (e.g. My Garden → Reminders) the big page header is hidden.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<List<ThisWeekItem>>(
      future: repo.thisWeek(),
      builder: (context, snap) {
        final items = snap.data ?? const [];
        final done = items.where((i) => i.completed).length;
        return CustomScrollView(
          slivers: [
            if (!embedded)
              SliverToBoxAdapter(child: _Header(done: done, total: items.length)),
            if (items.isNotEmpty)
              const SliverToBoxAdapter(child: _WeatherBanner()),
            if (snap.connectionState == ConnectionState.waiting)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (items.isEmpty)
              const SliverToBoxAdapter(child: _Empty())
            else
              ..._buildGroups(context, repo, items),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  List<Widget> _buildGroups(
      BuildContext context, GardenRepository repo, List<ThisWeekItem> items) {
    final byDay = <String, List<ThisWeekItem>>{};
    for (final i in items) {
      byDay.putIfAbsent(i.due, () => []).add(i);
    }
    final days = byDay.keys.toList()..sort();
    return [
      for (final day in days)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(_dayLabel(day, repo.today),
                      style: AppText.kicker(context)),
                ),
                for (final item in byDay[day]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TaskTile(item: item, repo: repo),
                  ),
              ],
            ),
          ),
        ),
    ];
  }

  static String _dayLabel(String iso, String today) {
    final d = parseIso(iso);
    if (iso == today) return 'TODAY';
    if (iso == toIso(addDays(parseIso(today), 1))) return 'TOMORROW';
    return DateFormat('EEEE d MMM').format(d).toUpperCase();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This week', style: AppText.kicker(context)),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      style: AppText.display(context),
                      children: const [
                        TextSpan(text: 'What to do '),
                        TextSpan(
                          text: 'in your garden',
                          style: TextStyle(color: AppColors.sprout),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _ProgressRing(done: done, total: total),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 6,
              backgroundColor: AppColors.sand,
              valueColor: const AlwaysStoppedAnimation(AppColors.sprout),
            ),
          ),
          Text('$done/$total', style: AppText.label(context)),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.item, required this.repo});
  final ThisWeekItem item;
  final GardenRepository repo;

  /// Waterings toggle. Path nodes (sow, plant out, feed, harvest…) open the
  /// plant's path so the user can back-date or skip with a reason (§7.1).
  Future<void> _tap(BuildContext context) async {
    if (item.kind == TaskKind.water || item.completed) {
      await repo.setTaskCompleted(item.taskId, !item.completed);
      return;
    }
    final plantId = item.plantId;
    if (plantId == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: plantId)));
  }

  @override
  Widget build(BuildContext context) {
    final hint = item.hint;
    return AppCard(
      onTap: () => _tap(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: KindMark(item.kind, size: 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(kindLabel(item.kind), style: AppText.heading(context)),
                    const SizedBox(width: 6),
                    CategoryDot(item.category),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.cropName, style: AppText.bodyMuted(context)),
                if (hint != null) ...[
                  const SizedBox(height: 8),
                  WeatherHintBadge(hint),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            item.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: item.completed ? AppColors.done : AppColors.hairline,
            size: 26,
          ),
        ],
      ),
    );
  }
}

/// Weather-aware banner (GrowIt shows one at the top of Reminders). Derived from
/// the same prototype sample forecast the hints use — a plain-language nudge +
/// today's temp. In production this reads the live weather layer.
class _WeatherBanner extends StatelessWidget {
  const _WeatherBanner();

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final obs = repo.lastObservations;
    if (obs == null) return const SizedBox.shrink();
    final byDate = {for (final o in obs) o.date: o};
    final today = byDate[repo.today];
    if (today == null) return const SizedBox.shrink();
    // What the overlay actually saw: rain over the last 3 days, heat ahead.
    var recentRain = 0.0;
    for (var d = 0; d < 3; d++) {
      recentRain += (byDate[toIso(addDays(parseIso(repo.today), -d))]?.precipMm ?? 0).toDouble();
    }
    final hotAhead = obs.where((o) => o.date.compareTo(repo.today) >= 0).any((o) => o.tempMaxC >= 30);
    final text = recentRain >= 10
        ? 'Rained ${recentRain.round()} mm in the last three days — waterings around today are skipped.'
        : hotAhead
            ? 'Heat ahead (30°C+) — containers dry out in a day, so waterings move earlier.'
            : 'Nothing dramatic in the forecast. The plan stands.';
    final wet = recentRain >= 10;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (wet ? AppColors.rain : hotAhead ? AppColors.heat : AppColors.sprout).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text, style: AppText.body(context, color: AppColors.ink))),
            const SizedBox(width: 12),
            Column(
              children: [
                Icon(wet ? Icons.umbrella : hotAhead ? Icons.wb_sunny : Icons.cloud_outlined,
                    color: wet ? AppColors.rain : hotAhead ? AppColors.heat : AppColors.muted, size: 26),
                const SizedBox(height: 2),
                Text('${today.tempMaxC.round()}°', style: AppText.label(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Text('🌿', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text('Nothing due this week', style: AppText.title(context)),
            const SizedBox(height: 6),
            Text('Add plants in Grow to see what to do.',
                style: AppText.bodyMuted(context), textAlign: TextAlign.center),
          ],
        ),
      );
}
