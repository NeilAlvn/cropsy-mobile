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
      return Text(_sent == 'error' ? 'Thanks — we check every report within a week.' : 'Thanks for the feedback.', style: AppText.caption(context, color: AppColors.sprout));
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
