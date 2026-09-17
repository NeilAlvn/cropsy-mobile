/// The season path (PRD 7.4): twelve months across, one lane per plant with
/// its outdoor sow window and harvest window, plus succession prompts with a
/// one-tap "Plan it". Scrolls horizontally; today is marked.
library;

import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';
import '../../design/icons.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/mascot.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../../timing/season.dart';
import '../repository_scope.dart';
import '../paywall/paywall_screen.dart';
import 'planner_grid_screen.dart';

const _monthAbbr = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
const _monthW = 44.0;

class SeasonPathView extends StatefulWidget {
  const SeasonPathView({super.key});

  @override
  State<SeasonPathView> createState() => _SeasonPathViewState();
}

class _SeasonPathViewState extends State<SeasonPathView> {
  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<List<SeasonNode>>(
      future: repo.seasonNodes(),
      builder: (context, snap) {
        final nodes = snap.data ?? const [];
        if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
        final year = parseIso(repo.today).year;
        final lanes = <String, List<SeasonNode>>{};
        for (final n in nodes) {
          if (n.kind == SeasonNodeKind.succession) continue;
          lanes.putIfAbsent(n.plantId ?? n.cropSlug, () => []).add(n);
        }
        final prompts = nodes.where((n) => n.kind == SeasonNodeKind.succession).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              onTap: () async {
                final gardens = await repo.gardens();
                if (gardens.isEmpty || !context.mounted) return;
                // §9: premium feature with a silent 7-day preview for free users.
                final premium = PurchaseScope.maybeOf(context)?.premium ?? false;
                if (!premium) {
                  const key = 'planner_preview_started_on';
                  final started = await repo.meta(key) ?? repo.today;
                  if (await repo.meta(key) == null) await repo.setMeta(key, started);
                  final days = parseIso(repo.today).difference(parseIso(started)).inDays;
                  if (days > 7) {
                    if (!context.mounted) return;
                    final bought = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const PaywallScreen(), fullscreenDialog: true));
                    if (bought != true) return;
                  }
                }
                if (!context.mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlannerGridScreen(garden: gardens.first)));
              },
              child: Row(children: [
                Icon(PhosphorIcons.gridFour, color: AppColors.sprout),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Str.gardenPlanner.of(context), style: AppText.label(context)),
                    Text(Str.plannerBlurb.of(context), style: AppText.caption(context)),
                  ]),
                ),
                Icon(PhosphorIcons.caretRight, color: AppColors.muted),
              ]),
            ),
            const SizedBox(height: 18),
            SectionHeader('Your season'),
            if (lanes.isEmpty)
              const MascotSays(pose: MascotPose.idle, text: 'Add a plant and the season lays itself out here.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: ScrollController(
                  initialScrollOffset: ((parseIso(repo.today).month - 3).clamp(0, 6)) * _monthW,
                ),
                child: SizedBox(
                  width: 12 * _monthW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MonthHeader(today: repo.today),
                      for (final e in lanes.entries)
                        _Lane(label: repo.cropName(e.value.first.cropSlug), nodes: e.value, year: year),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(children: [
              _Legend(AppColors.bandSowOutdoor, 'sow / plant out'),
              const SizedBox(width: 12),
              _Legend(AppColors.bandHarvest, 'harvest'),
            ]),
            if (prompts.isNotEmpty) ...[
              const SizedBox(height: 18),
              SectionHeader('Bed frees up'),
              for (final p in prompts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Row(children: [
                      const Mascot(MascotPose.pointing, size: 40),
                      const SizedBox(width: 12),
                      Expanded(child: Text(p.note?.en ?? '', style: AppText.body(context))),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final gardens = await repo.gardens();
                          if (gardens.isEmpty) return;
                          final crop = repo.cropBySlug(p.cropSlug);
                          await repo.addPlant(gardenId: gardens.first.id, cropSlug: p.cropSlug, potLitres: crop?.minPotLitres?.toInt());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Str.addedToPlanning(repo.cropBySlug(p.cropSlug)?.names.of(context) ?? p.cropSlug).of(context))));
                            setState(() {});
                          }
                        },
                        child: Text(Str.planIt.of(context), style: AppText.label(context, color: AppColors.sprout)),
                      ),
                    ]),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.today});
  final String today;

  @override
  Widget build(BuildContext context) {
    final m = parseIso(today).month;
    return Row(children: [
      for (var i = 0; i < 12; i++)
        SizedBox(
          width: _monthW,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: i + 1 == m ? BoxDecoration(color: AppColors.sprout, borderRadius: BorderRadius.circular(8)) : null,
              child: Text(_monthAbbr[i], style: AppText.caption(context, color: i + 1 == m ? AppColors.onAccent : AppColors.muted)),
            ),
          ),
        ),
    ]);
  }
}

class _Lane extends StatelessWidget {
  const _Lane({required this.label, required this.nodes, required this.year});
  final String label;
  final List<SeasonNode> nodes;
  final int year;

  double _x(String iso) {
    final d = parseIso(iso);
    if (d.year < year) return 0;
    if (d.year > year) return 12 * _monthW;
    return ((d.month - 1) + (d.day - 1) / 31) * _monthW;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption(context)),
          SizedBox(
            height: 14,
            child: Stack(children: [
              Container(height: 14, decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(7))),
              for (final n in nodes)
                Positioned(
                  left: _x(n.start),
                  width: (_x(n.end) - _x(n.start)).clamp(6.0, 12 * _monthW),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: n.kind == SeasonNodeKind.harvestWindow ? AppColors.bandHarvest : AppColors.bandSowOutdoor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.text);
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(text, style: AppText.caption(context)),
      ]);
}
