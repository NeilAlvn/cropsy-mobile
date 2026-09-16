/// Shared Cropsy UI components + small mappers (kind emoji, garden labels,
/// weather-hint badges). Keeps the feature screens declarative and on-brand.
library;

import 'package:flutter/material.dart';

import '../db/database.dart' show GardenKind;
import '../timing/weather_adjust.dart';
import 'brutal.dart';
import 'colors.dart';
import 'motion.dart';
import 'typography.dart';

/// Illustration per task kind — the mark shown in task tiles. Base 7: emoji are
/// not icons, so every kind has a drawn asset under assets/marks.
String kindMark(TaskKind kind) => switch (kind) {
      TaskKind.water => 'water',
      TaskKind.sow => 'sow',
      TaskKind.transplant => 'transplant',
      TaskKind.harvest => 'harvest',
      TaskKind.feed => 'feed',
      TaskKind.potOn => 'pot_on',
      TaskKind.thin => 'thin',
    };

/// The mark in a circle, sized for a list row.
class KindMark extends StatelessWidget {
  const KindMark(this.kind, {super.key, this.size = 40});

  final TaskKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: AppColors.tile, shape: BoxShape.circle),
        padding: EdgeInsets.all(size * 0.08),
        child: Image.asset('assets/marks/${kindMark(kind)}.png',
            fit: BoxFit.contain, excludeFromSemantics: true),
      );
}

String kindLabel(TaskKind kind) => switch (kind) {
      TaskKind.water => 'Water',
      TaskKind.sow => 'Sow',
      TaskKind.transplant => 'Plant out',
      TaskKind.harvest => 'Harvest',
      TaskKind.feed => 'Feed',
      TaskKind.potOn => 'Pot on',
      TaskKind.thin => 'Thin',
    };

String gardenKindEmoji(GardenKind k) => switch (k) {
      GardenKind.balcony => '🪟',
      GardenKind.garden => '🌳',
      GardenKind.allotment => '🚜',
    };

String gardenKindLabel(GardenKind k) => switch (k) {
      GardenKind.balcony => 'Balcony',
      GardenKind.garden => 'Garden',
      GardenKind.allotment => 'Allotment',
    };

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.accent,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    // Base 8.1: disabled swaps tokens, it never fades the whole button.
    final fill = disabled ? AppColors.tile : color;
    final fg = disabled ? AppColors.inkPlaceholder : AppColors.onAccent;
    return Pressable(
      onTap: onPressed,
      haptic: Haptics.press,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(Neo.radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppText.button(context, color: fg)),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      haptic: Haptics.press,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(Neo.radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppText.button(context, color: AppColors.onInk)),
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.haptic = Haptics.selection,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  /// The haptic the press fires. Cards whose tap completes something pass
  /// [Haptics.complete]; passing null leaves the press silent.
  final void Function()? haptic;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: haptic,
      child: Container(
        decoration: Neo.box(),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class CategoryDot extends StatelessWidget {
  const CategoryDot(this.category, {super.key, this.size = 8});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.categoryColor(category),
          shape: BoxShape.circle,
        ),
      );
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.color, this.bg, this.icon});

  final String label;
  final Color? color;
  final Color? bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.ink;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg ?? AppColors.tile,
        borderRadius: BorderRadius.circular(Neo.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 6)],
          Text(label, style: AppText.caption(context, color: fg)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Row(
          children: [
            Text(text, style: AppText.heading(context)),
            const Spacer(),
            ?trailing,
          ],
        ),
      );
}

/// Weather-aware hint badge (F4) derived from an [Adjustment]. Colour + copy
/// depend on the action; returns null for `none`.
class WeatherHintBadge extends StatelessWidget {
  const WeatherHintBadge(this.adjustment, {super.key});

  final Adjustment adjustment;

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (adjustment.action) {
      AdjustAction.skip => (AppColors.rain, Icons.water_drop, 'Enough rain'),
      AdjustAction.bringForward => (AppColors.heat, Icons.wb_sunny, 'Heat coming'),
      AdjustAction.defer => (AppColors.frost, Icons.ac_unit, 'Soil too cold'),
      AdjustAction.none => (AppColors.muted, Icons.info_outline, ''),
    };
    return Pill(
      label: text,
      icon: icon,
      color: color,
      bg: color.withValues(alpha: 0.12),
    );
  }
}

/// PRD §4.3: draft content is visibly labelled during the beta.
class DraftBadge extends StatelessWidget {
  const DraftBadge({super.key, this.compact = false});

  /// Short form for list tiles.
  final bool compact;

  @override
  Widget build(BuildContext context) => Pill(label: compact ? 'Concept' : 'Concept — nog niet gecontroleerd', icon: Icons.edit_note, color: AppColors.clay);
}
