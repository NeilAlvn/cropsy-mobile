/// The pieces every onboarding step is built from.
///
/// One chrome (back, progress, mascot, question) and one tile, so the eight
/// steps differ only in what they ask. Everything reads the VisionTech tokens:
/// flat surfaces on the canvas, no borders and no shadows on content, pill
/// buttons, and the accent's soft tint for a chosen answer.
library;

import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/brutal.dart';
import '../../design/components.dart';
import '../../design/icons.dart';
import '../../design/mascot.dart';
import '../../design/motion.dart';
import '../../design/typography.dart';
import '../../l10n/app_lang.dart';
import '../../timing/types.dart';
import '../../l10n/strings.dart';

/// The frame around every step: where you are, who is asking, and the way on.
///
/// The mascot is here rather than on each step because it belongs to the frame
/// — it is the one asking — and because 72 points is above the size at which it
/// breathes, so it is alive on every screen rather than on three of sixteen.
class StepFrame extends StatelessWidget {
  const StepFrame({
    super.key,
    required this.pose,
    required this.title,
    required this.onNext,
    this.subtitle,
    this.body,
    this.buttonLabel,
    this.enabled = true,
    this.onBack,
    this.onSkip,
    this.progress,
  });

  final MascotPose pose;
  final LocalizedText title;
  final LocalizedText? subtitle;

  /// Whatever the step asks with. Scrolls; the frame does not.
  final Widget? body;

  final VoidCallback onNext;
  final String? buttonLabel;
  final bool enabled;

  /// Null on the first question, where there is nothing to go back to and the
  /// slot carries "Skip" instead.
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  /// 0 to 1. Null hides the bar, for the steps that are not questions.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(progress: progress, onBack: onBack, onSkip: onSkip),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                children: [
                  // A list stretches its children, and a centred mascot over
                  // left-aligned text reads as an accident.
                  Align(alignment: Alignment.centerLeft, child: Mascot(pose, size: 72)),
                  const SizedBox(height: 14),
                  Text(title.of(context), style: AppText.title(context)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle!.of(context), style: AppText.bodyMuted(context)),
                  ],
                  if (body != null) ...[const SizedBox(height: 18), body!],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: PrimaryButton(
                label: buttonLabel ?? Str.continueLabel.of(context),
                icon: PhosphorIcons.arrowRight,
                onPressed: enabled ? onNext : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A back arrow, the bar, and nothing else. The old header was a bordered card
/// floating over the page; the base says a hairline and a bar are the edge.
class _Header extends StatelessWidget {
  const _Header({this.progress, this.onBack, this.onSkip});

  final double? progress;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: onBack == null
                ? null
                : Pressable(
                    onTap: onBack,
                    child: Icon(PhosphorIcons.caretLeft, size: 22, color: AppColors.ink),
                  ),
          ),
          if (progress != null)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Neo.radiusPill),
                child: TweenAnimationBuilder<double>(
                  // The bar catches up to the new step rather than jumping to
                  // it, which is the only thing on screen that says a step was
                  // just completed.
                  tween: Tween(begin: 0, end: progress),
                  duration: motion[Motion.standard],
                  curve: Motion.easeEnter,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    backgroundColor: AppColors.tile,
                    valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          if (onSkip != null) ...[
            const SizedBox(width: 14),
            Pressable(
              onTap: onSkip,
              child: Text(
                Str.skip.of(context),
                style: AppText.label(context, color: AppColors.inkMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One answer. Flat tile on the canvas, the accent's soft tint when it is
/// chosen, and a check that grows in rather than appearing.
class SelectTile extends StatelessWidget {
  const SelectTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final fg = selected ? AppColors.onAccentSoft : AppColors.ink;
    final art = icon != null
        ? Icon(icon, size: 22, color: selected ? AppColors.onAccentSoft : AppColors.accent)
        : leading;
    return Pressable(
      onTap: onTap,
      haptic: Haptics.selection,
      child: AnimatedContainer(
        duration: motion[Motion.micro],
        curve: Motion.easeEnter,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.tile,
          borderRadius: BorderRadius.circular(Neo.radiusTile),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            if (art != null) ...[art, const SizedBox(width: 12)],
            Expanded(
              child: Text(
                label,
                style: AppText.label(context, color: fg),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              scale: selected ? 1 : 0.4,
              duration: motion[Motion.micro],
              curve: Motion.easeEnter,
              child: AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: motion[Motion.micro],
                child: Icon(PhosphorIcons.checkCircle, size: 22, color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list of answers, staggered in so the screen arrives rather than appears.
class ChoiceList extends StatelessWidget {
  const ChoiceList({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<(String, LocalizedText, IconData)> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Column(
    // The list above hands this unbounded height; a Column that wants the
    // maximum of that is the bug that blanked a whole step.
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ArriveIn(
            index: i,
            child: SelectTile(
              icon: options[i].$3,
              label: options[i].$2.of(context),
              selected: selected.contains(options[i].$1),
              onTap: () => onToggle(options[i].$1),
            ),
          ),
        ),
    ],
  );
}

/// A smaller heading inside a step that asks two things at once.
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.text, {super.key});

  final LocalizedText text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.of(context), style: AppText.label(context, color: AppColors.inkMuted)),
  );
}

/// One line on a soft tint — the beat after an answer that deserves an answer
/// back. With a pose the mascot says it; without one it is just a note, which
/// is what a screen that already has a mascot in its frame needs.
class MascotNote extends StatelessWidget {
  const MascotNote({super.key, this.pose, required this.text});

  final MascotPose? pose;
  final LocalizedText text;

  @override
  Widget build(BuildContext context) => ArriveIn(
    index: 0,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(Neo.radius),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pose != null) ...[Mascot(pose!, size: 44), const SizedBox(width: 12)],
          Expanded(
            child: Text(
              text.of(context),
              style: AppText.body(context, color: AppColors.onAccentSoft),
            ),
          ),
        ],
      ),
    ),
  );
}
