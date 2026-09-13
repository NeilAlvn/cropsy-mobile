/// The per-plant Duolingo path (PRD §7.1): a vertical list of nodes, past at
/// the top, future below. Tapping a node opens the log sheet (done today,
/// back-date, skip with reason). A logged date that moves the plan shows the
/// mascot's "not behind" sheet instead of any "overdue" state.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/mascot.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../../timing/replan.dart';
import '../../timing/types.dart';
import '../repository_scope.dart';
import 'garden_repository.dart';

MascotPose poseFor(NodeKind k) => switch (k) {
      NodeKind.sow => MascotPose.holdingSeedling,
      NodeKind.potOn => MascotPose.holdingSeedling,
      NodeKind.transplant => MascotPose.pointing,
      NodeKind.thin => MascotPose.thinking,
      NodeKind.feed => MascotPose.idle,
      NodeKind.water => MascotPose.watering,
      NodeKind.harvest => MascotPose.celebrating,
      NodeKind.harvested => MascotPose.celebrating,
    };

String nodeTitle(NodeKind k) => switch (k) {
      NodeKind.sow => 'Sow',
      NodeKind.potOn => 'Pot on',
      NodeKind.transplant => 'Plant out',
      NodeKind.thin => 'Thin seedlings',
      NodeKind.feed => 'Feed',
      NodeKind.water => 'Water',
      NodeKind.harvest => 'Harvest window',
      NodeKind.harvested => 'Harvested',
    };

enum _NodeState { done, skipped, current, upcoming }

_NodeState _stateOf(PathNode n, String today) {
  if (n.loggedOn != null) return _NodeState.done;
  if (n.skipped) return _NodeState.skipped;
  if (n.due.compareTo(today) <= 0) return _NodeState.current;
  return _NodeState.upcoming;
}

String _fmt(String iso) => DateFormat('d MMM').format(parseIso(iso));

class TimelineView extends StatefulWidget {
  const TimelineView({super.key, required this.plantId});
  final String plantId;

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<List<PathNode>>(
      future: repo.pathFor(widget.plantId),
      builder: (context, snap) {
        final nodes = snap.data ?? const [];
        if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
        if (nodes.isEmpty) {
          return const MascotSays(
            pose: MascotPose.idle,
            text: 'No path yet. Press Start when this plant goes in — the path builds itself.',
          );
        }
        final today = repo.today;
        return Column(
          children: [
            for (var i = 0; i < nodes.length; i++)
              _NodeTile(
                node: nodes[i],
                state: _stateOf(nodes[i], today),
                isLast: i == nodes.length - 1,
                onTap: () => _openNode(repo, nodes[i]),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openNode(GardenRepository repo, PathNode node) async {
    final action = await showModalBottomSheet<_LogAction>(
      context: context,
      backgroundColor: AppColors.paper,
      builder: (_) => _LogSheet(node: node, today: repo.today),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _LogDone(:final on):
        final result = await repo.logNode(widget.plantId, node.id, on);
        if (!mounted) return;
        setState(() {});
        if (result.shiftDays != 0 || result.warnings.isNotEmpty) {
          await showModalBottomSheet<void>(
            context: context,
            backgroundColor: AppColors.paper,
            builder: (_) => _NotBehindSheet(result: result, anchor: node),
          );
        }
      case _LogSkip(:final reason):
        await repo.skipNode(node.id, reason);
        if (mounted) setState(() {});
    }
  }
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({required this.node, required this.state, required this.isLast, required this.onTap});
  final PathNode node;
  final _NodeState state;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dim = state == _NodeState.upcoming || state == _NodeState.skipped;
    final accent = switch (state) {
      _NodeState.done => AppColors.done,
      _NodeState.current => AppColors.clay,
      _NodeState.skipped => AppColors.muted,
      _NodeState.upcoming => AppColors.border,
    };
    final when = node.until == null ? _fmt(node.due) : '${_fmt(node.due)} – ${_fmt(node.until!)}';
    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 64,
              child: Column(
                children: [
                  Opacity(
                    opacity: dim ? 0.45 : 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 3),
                      ),
                      child: Mascot(poseFor(node.kind), size: 44),
                    ),
                  ),
                  if (!isLast) Expanded(child: Container(width: 3, color: AppColors.border)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(nodeTitle(node.kind),
                          style: AppText.heading(context, color: dim ? AppColors.muted : AppColors.ink)),
                      const Spacer(),
                      if (state == _NodeState.done)
                        Pill(label: 'Done ${_fmt(node.loggedOn!)}', color: AppColors.done, icon: Icons.check)
                      else if (state == _NodeState.current)
                        const Pill(label: 'Now', color: AppColors.clay, icon: Icons.play_arrow)
                      else if (state == _NodeState.skipped)
                        const Pill(label: 'Skipped', icon: Icons.redo),
                    ]),
                    const SizedBox(height: 2),
                    Text(when, style: AppText.bodyMuted(context)),
                    if (node.movedReason != null && !node.skipped) ...[
                      const SizedBox(height: 4),
                      Text('Moved from ${_fmt(node.plannedDue)} · ${node.movedReason!.en}',
                          style: AppText.caption(context, color: AppColors.sky)),
                    ],
                    if (node.skipped && node.movedReason != null)
                      Text(node.movedReason!.en, style: AppText.caption(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

sealed class _LogAction {}

class _LogDone extends _LogAction {
  _LogDone(this.on);
  final String on;
}

class _LogSkip extends _LogAction {
  _LogSkip(this.reason);
  final LocalizedText reason;
}

const _skipReasons = <LocalizedText>[
  LocalizedText(nl: 'Het regende', en: 'It rained'),
  LocalizedText(nl: 'Niet nodig', en: 'Not needed'),
  LocalizedText(nl: 'Geen tijd', en: 'No time'),
];

class _LogSheet extends StatelessWidget {
  const _LogSheet({required this.node, required this.today});
  final PathNode node;
  final String today;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MascotSays(pose: poseFor(node.kind), text: '${nodeTitle(node.kind)} · planned ${_fmt(node.plannedDue)}'),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Did it today', onPressed: () => Navigator.pop(context, _LogDone(today))),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'I did this on…',
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: parseIso(today),
                  firstDate: DateTime(2020),
                  lastDate: parseIso(today),
                );
                if (picked != null && context.mounted) {
                  Navigator.pop(context, _LogDone(toIso(DateTime.utc(picked.year, picked.month, picked.day))));
                }
              },
            ),
            const SizedBox(height: 16),
            Text('Skip this one', style: AppText.label(context, color: AppColors.muted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final r in _skipReasons)
                  ActionChip(label: Text(r.en), onPressed: () => Navigator.pop(context, _LogSkip(r))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// PRD §7.2: "not behind, here's the new plan".
class _NotBehindSheet extends StatelessWidget {
  const _NotBehindSheet({required this.result, required this.anchor});
  final ReplanResult result;
  final PathNode anchor;

  @override
  Widget build(BuildContext context) {
    final d = result.shiftDays;
    final moved = result.nodes.where((n) => n.movedReason != null && n.loggedOn == null).length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MascotSays(
              pose: result.warnings.isEmpty ? MascotPose.shrug : MascotPose.frost,
              text: d == 0
                  ? 'Logged. Nothing else needed to move.'
                  : "You're not behind. ${nodeTitle(anchor.kind)} was ${d.abs()} days "
                      "${d > 0 ? 'later' : 'earlier'} than planned, so $moved upcoming "
                      "step${moved == 1 ? '' : 's'} moved with it.",
            ),
            for (final w in result.warnings) ...[
              const SizedBox(height: 12),
              AppCard(child: Text(w.reason.en, style: AppText.body(context))),
            ],
            const SizedBox(height: 16),
            PrimaryButton(label: 'Got it', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
