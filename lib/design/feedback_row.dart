/// "Do you like the information?" (PRD 3.9) and the section "…" menu (2.7):
/// like / dislike / error in content / suggestion. Writes the feedback table.
/// Never a rate-the-app prompt.
library;

import 'package:flutter/material.dart';

import '../features/repository_scope.dart';
import 'colors.dart';
import 'typography.dart';

class FeedbackRow extends StatefulWidget {
  const FeedbackRow({super.key, required this.targetKind, required this.targetId});
  final String targetKind;
  final String targetId;

  @override
  State<FeedbackRow> createState() => _FeedbackRowState();
}

class _FeedbackRowState extends State<FeedbackRow> {
  String? _sent;

  Future<void> _send(String sentiment, {String? body}) async {
    await RepositoryScope.of(context).addFeedback(
      targetKind: widget.targetKind,
      targetId: widget.targetId,
      sentiment: sentiment,
      body: body,
    );
    if (mounted) setState(() => _sent = sentiment);
  }

  Future<void> _report() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('What is wrong?', style: AppText.title(context)),
        content: TextField(controller: c, autofocus: true, maxLines: 3, decoration: const InputDecoration(hintText: 'e.g. sowing window is too early for Groningen')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Send')),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) await _send('error', body: text.trim());
  }

  @override
  Widget build(BuildContext context) {
    if (_sent != null) {
      return Text(_sent == 'error' ? 'Thanks. We check every report within a week.' : 'Thanks for the feedback.', style: AppText.caption(context, color: AppColors.sprout));
    }
    return Row(children: [
      Text('Is this information useful?', style: AppText.caption(context)),
      const Spacer(),
      IconButton(icon: const Icon(Icons.thumb_up_outlined, size: 20, color: AppColors.muted), onPressed: () => _send('like')),
      IconButton(icon: const Icon(Icons.thumb_down_outlined, size: 20, color: AppColors.muted), onPressed: () => _send('dislike')),
      TextButton(onPressed: _report, child: Text('Report error', style: AppText.caption(context, color: AppColors.clay))),
    ]);
  }
}

/// PRD 2.7: the "…" menu on a Home section — like / error in content /
/// suggestion. Same table, same never-a-rate-prompt rule.
class SectionFeedbackMenu extends StatelessWidget {
  const SectionFeedbackMenu({super.key, required this.targetKind, required this.targetId});
  final String targetKind;
  final String targetId;

  Future<void> _text(BuildContext context, String sentiment, String title) async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppText.title(context)),
        content: TextField(controller: c, autofocus: true, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Send')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    await RepositoryScope.of(context).addFeedback(targetKind: targetKind, targetId: targetId, sentiment: sentiment, body: text.trim());
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks, noted.')));
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: AppColors.muted),
      color: AppColors.surface,
      onSelected: (v) async {
        switch (v) {
          case 'like':
            await RepositoryScope.of(context).addFeedback(targetKind: targetKind, targetId: targetId, sentiment: 'like');
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks!')));
          case 'error':
            await _text(context, 'error', 'What is wrong here?');
          case 'suggestion':
            await _text(context, 'suggestion', 'What would make this better?');
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'like', child: Text('I like this')),
        PopupMenuItem(value: 'error', child: Text('Error in content')),
        PopupMenuItem(value: 'suggestion', child: Text('Suggestion')),
      ],
    );
  }
}
