/// Shared Cropsy UI components + small mappers (kind emoji, garden labels,
/// weather-hint badges). Keeps the feature screens declarative and on-brand.
library;

import 'package:flutter/material.dart';

import '../db/database.dart' show GardenKind;
import '../timing/weather_adjust.dart';
import 'brutal.dart';
import 'colors.dart';
import 'typography.dart';

/// Emoji per task kind — the friendly, glanceable signal in task tiles.
String kindEmoji(TaskKind kind) => switch (kind) {
      TaskKind.water => '💧',
      TaskKind.sow => '🌱',
      TaskKind.transplant => '🌿',
      TaskKind.harvest => '🧺',
      TaskKind.feed => '🧴',
      TaskKind.potOn => '🪴',
      TaskKind.thin => '✂️',
    };

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
    this.color = AppColors.sprout,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: Neo.box(
          color: disabled ? color.withValues(alpha: 0.4) : color,
          shadowed: !disabled,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppText.button(context)),
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: Neo.box(color: AppColors.surface),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppText.button(context, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: Neo.box(),
        padding: padding ?? const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class CategoryDot extends StatelessWidget {
  const CategoryDot(this.category, {super.key, this.size = 12});

  final String category;
  final double size;

  /// A bordered square swatch — reads as intentional, not a stray bullet.
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.categoryColor(category),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.border, width: 1.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? AppColors.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
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
        padding: const EdgeInsets.only(bottom: 10, top: 4),
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
      AdjustAction.skip => (AppColors.rain, Icons.water_drop, 'Skip — enough rain'),
      AdjustAction.bringForward => (AppColors.heat, Icons.wb_sunny, 'Water earlier — heat'),
      AdjustAction.defer => (AppColors.frost, Icons.ac_unit, 'Hold — soil too cold'),
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
