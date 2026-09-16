/// GrowIt-style rich components: photo cards, filter chips, segmented tabs, a
/// difficulty gauge. Built on the fresh Cropsy identity.
library;

import 'package:flutter/material.dart';
import '../l10n/app_lang.dart';
import '../design/icons.dart';

import '../data/crop_derived.dart';
import '../timing/types.dart';
import 'brutal.dart';
import 'colors.dart';
import 'components.dart';
import 'crop_image.dart';
import 'glass.dart';
import 'motion.dart';
import 'typography.dart';

/// A photo-forward crop card (Home grid, collection rows).
class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.crop,
    required this.onTap,
    this.subtitle,
    this.width,
  });

  final Crop crop;
  final VoidCallback onTap;
  final String? subtitle;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Pressable(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: Neo.box(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CropImage(slug: crop.slug, category: crop.category),
                    if (crop.draft)
                      const Positioned(left: 8, top: 8, child: DraftBadge(compact: true)),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: GlassSurface(
                        borderRadius: BorderRadius.circular(16),
                        blur: 16,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(PhosphorIcons.heartStraight,
                              size: 16, color: AppColors.ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CategoryDot(crop.category),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(crop.names.of(context),
                              style: AppText.subheading(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle ?? _defaultSubtitle(crop),
                      style: AppText.caption(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _defaultSubtitle(Crop crop) {
    final diff = difficultyLabel(difficultyOf(crop));
    if (crop.containerOk && crop.minPotLitres != null) {
      return '${crop.minPotLitres}L pot · $diff';
    }
    return diff;
  }
}

/// Horizontal single-select chip row.
class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  /// (value, label) pairs.
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 4, right: 4),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (value, label) = options[i];
          final on = value == selected;
          return Pressable(
            onTap: () => onSelect(value),
            child: Container(
              height: 36,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: on ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(Neo.radiusPill),
              ),
              child: Text(
                label,
                style: AppText.label(context,
                    color: on ? AppColors.onInk : AppColors.ink),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pill segmented control (My Garden sub-tabs, crop-detail sections).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(Neo.radiusPill),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(i),
                child: Container(
                  height: 38,
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 4),
                  decoration: i == index
                      ? BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(Neo.radiusPill),
                          boxShadow: Neo.float,
                        )
                      : null,
                  child: Text(
                    labels[i],
                    style: AppText.label(context,
                        color: i == index ? AppColors.ink : AppColors.inkMuted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Difficulty gauge (a simple arc + label).
class DifficultyGauge extends StatelessWidget {
  const DifficultyGauge({super.key, required this.difficulty});
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (difficulty) {
      Difficulty.easy => (AppColors.easy, 'Easy'),
      Difficulty.medium => (AppColors.medium, 'Medium'),
      Difficulty.hard => (AppColors.hard, 'Hard'),
    };
    final value = switch (difficulty) {
      Difficulty.easy => 0.33,
      Difficulty.medium => 0.66,
      Difficulty.hard => 1.0,
    };
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 54,
          child: CustomPaint(painter: _GaugePainter(value, color)),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppText.title(context, color: color)),
        Text('Overall difficulty', style: AppText.caption(context)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, (size.height - 6) * 2);
    final bg = Paint()
      ..color = AppColors.sand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    // 180° arc from left to right.
    canvas.drawArc(rect, 3.14159, 3.14159, false, bg);
    canvas.drawArc(rect, 3.14159, 3.14159 * value, false, fg);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}
