/// Logging a path node, from wherever the node is shown.
///
/// The plant's own timeline and the season path both need the same three acts:
/// did it today, did it on a date, skip it with a reason. And both need the
/// same answer afterwards — PRD §7.2's "you are not behind, here is the new
/// plan" — so the flow lives here rather than inside one screen.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/mascot.dart';
import '../../design/motion.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../../timing/replan.dart';
import '../../timing/types.dart';
import 'garden_repository.dart';

MascotPose poseForNode(NodeKind k) => switch (k) {
      NodeKind.sow => MascotPose.holdingSeedling,
      NodeKind.potOn => MascotPose.holdingSeedling,
      NodeKind.transplant => MascotPose.pointing,
      NodeKind.thin => MascotPose.thinking,
      NodeKind.feed => MascotPose.idle,
      NodeKind.water => MascotPose.watering,
      NodeKind.harvest => MascotPose.celebrating,
      NodeKind.harvested => MascotPose.celebrating,
    };

String nodeKindTitle(NodeKind k) => switch (k) {
      NodeKind.sow => 'Sow',
      NodeKind.potOn => 'Pot on',
      NodeKind.transplant => 'Plant out',
      NodeKind.thin => 'Thin seedlings',
      NodeKind.feed => 'Feed',
      NodeKind.water => 'Water',
      NodeKind.harvest => 'Harvest window',
      NodeKind.harvested => 'Harvested',
    };

String formatDay(String iso) => DateFormat('d MMM').format(parseIso(iso));

/// Opens the log sheet for [node] and applies what the gardener chose.
/// Returns true when something changed, so the caller can refresh.
Future<bool> openNodeLog(
  BuildContext context,
  GardenRepository repo,
  String plantId,
  PathNode node,
) async {
  final action = await showModalBottomSheet<_LogAction>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _LogSheet(node: node, today: repo.today),
  );
  if (action == null || !context.mounted) return false;

  switch (action) {
    case _LogDone(:final on):
      final result = await repo.logNode(plantId, node.id, on);
      if (!context.mounted) return true;
      Haptics.complete();
      if (result.shiftDays != 0 || result.warnings.isNotEmpty) {
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (_) => _NotBehindSheet(result: result, anchor: node),
        );
      }
      return true;
    case _LogSkip(:final reason):
      await repo.skipNode(node.id, reason);
      return true;
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
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MascotSays(
                pose: poseForNode(node.kind),
                text: '${nodeKindTitle(node.kind)} · planned ${formatDay(node.plannedDue)}',
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Did it today',
                onPressed: () => Navigator.pop(context, _LogDone(today)),
              ),
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
                    Navigator.pop(
                      context,
                      _LogDone(toIso(DateTime.utc(picked.year, picked.month, picked.day))),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              Text('Skip this one', style: AppText.label(context, color: AppColors.inkMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in _skipReasons)
                    ActionChip(
                      label: Text(r.en),
                      onPressed: () => Navigator.pop(context, _LogSkip(r)),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

/// PRD §7.2: "not behind, here is the new plan".
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
                  : "You're not behind. ${nodeKindTitle(anchor.kind)} was ${d.abs()} days "
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
