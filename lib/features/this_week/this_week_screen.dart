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
import '../garden/garden_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    final hint = item.hint;
    return AppCard(
      onTap: () => repo.setTaskCompleted(item.taskId, !item.completed),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(kindEmoji(item.kind),
                style: const TextStyle(fontSize: 22)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.rain.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Warm and dry ahead — containers dry out fast, so keep an eye '
                'on watering.',
                style: AppText.body(context, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                const Icon(Icons.wb_sunny, color: AppColors.heat, size: 26),
                const SizedBox(height: 2),
                Text('24°', style: AppText.label(context)),
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
