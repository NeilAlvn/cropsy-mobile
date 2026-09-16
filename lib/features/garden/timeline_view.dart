/// The per-plant Duolingo path (PRD §7.1): a vertical list of nodes, past at
/// the top, future below. Tapping a node opens the log sheet (done today,
/// back-date, skip with reason). A logged date that moves the plan shows the
/// mascot's "not behind" sheet instead of any "overdue" state.
library;

import 'package:flutter/material.dart';
import '../../l10n/mascot_lines.dart';
import '../../design/icons.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/mascot.dart';
import '../../design/typography.dart';
import '../../timing/replan.dart';
import '../repository_scope.dart';
import 'garden_repository.dart';
import 'log_node_flow.dart';

MascotPose poseFor(NodeKind k) => poseForNode(k);

String nodeTitle(NodeKind k) => nodeKindTitle(k);

enum _NodeState { done, skipped, current, upcoming }

_NodeState _stateOf(PathNode n, String today) {
  if (n.loggedOn != null) return _NodeState.done;
  if (n.skipped) return _NodeState.skipped;
  if (n.due.compareTo(today) <= 0) return _NodeState.current;
  return _NodeState.upcoming;
}

String _fmt(String iso) => formatDay(iso);

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
          return const MascotSays.say(
            pose: MascotPose.idle,
            line: MascotLines.pathEmpty,
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
    final changed = await openNodeLog(context, repo, widget.plantId, node);
    if (changed && mounted) setState(() {});
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
                        Pill(label: 'Done ${_fmt(node.loggedOn!)}', color: AppColors.done, icon: PhosphorIcons.check)
                      else if (state == _NodeState.current)
                        Pill(label: 'Now', color: AppColors.clay, icon: PhosphorIcons.play)
                      else if (state == _NodeState.skipped)
                        Pill(label: 'Skipped', icon: PhosphorIcons.arrowClockwise),
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
