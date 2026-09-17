/// "Do you like the information?" (PRD 3.9) and the section "…" menu (2.7):
/// like / dislike / error in content / suggestion. Writes the feedback table.
/// Never a rate-the-app prompt.
library;

import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../l10n/app_lang.dart';
import '../design/icons.dart';

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
        title: Text(Str.whatIsWrong.of(context), style: AppText.title(context)),
        content: TextField(controller: c, autofocus: true, maxLines: 3, decoration: InputDecoration(hintText: Str.whatIsWrongHint.of(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(Str.cancel.of(context))),
          TextButton(onPressed: () => Navigator.pop(context, c.text), child: Text(Str.send.of(context))),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) await _send('error', body: text.trim());
  }

  @override
  Widget build(BuildContext context) {
    if (_sent != null) {
      return Text((_sent == 'error' ? Str.thanksChecked : Str.thanksFeedback).of(context), style: AppText.caption(context, color: AppColors.sprout));
    }
    return Row(children: [
      Text(Str.isThisUseful.of(context), style: AppText.caption(context)),
      const Spacer(),
      IconButton(icon: Icon(PhosphorIcons.thumbsUp, size: 20, color: AppColors.muted), onPressed: () => _send('like')),
      IconButton(icon: Icon(PhosphorIcons.thumbsDown, size: 20, color: AppColors.muted), onPressed: () => _send('dislike')),
      TextButton(onPressed: _report, child: Text(Str.reportError.of(context), style: AppText.caption(context, color: AppColors.clay))),
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text(Str.cancel.of(context))),
          TextButton(onPressed: () => Navigator.pop(context, c.text), child: Text(Str.send.of(context))),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    await RepositoryScope.of(context).addFeedback(targetKind: targetKind, targetId: targetId, sentiment: sentiment, body: text.trim());
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Str.thanksNoted.of(context))));
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(PhosphorIcons.dotsThree, color: AppColors.muted),
      color: AppColors.surface,
      onSelected: (v) async {
        switch (v) {
          case 'like':
            await RepositoryScope.of(context).addFeedback(targetKind: targetKind, targetId: targetId, sentiment: 'like');
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Str.thanksNoted.of(context))));
          case 'error':
            await _text(context, 'error', 'What is wrong here?');
          case 'suggestion':
            await _text(context, 'suggestion', 'What would make this better?');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'like', child: Text(Str.likeThis.of(context))),
        PopupMenuItem(value: 'error', child: Text(Str.errorInContent.of(context))),
        PopupMenuItem(value: 'suggestion', child: Text(Str.suggestion.of(context))),
      ],
    );
  }
}
