/// Crop photo with a graceful fallback. Loads `assets/crops/<slug>.jpg`
/// (free-licensed placeholders, see assets/crops/CREDITS.md); if the asset is
/// missing or fails to decode, shows a tinted placeholder in the crop's category
/// colour so the layout never breaks. Swap the assets for owned photography later.
library;

import 'package:flutter/material.dart';

import 'colors.dart';

class CropImage extends StatelessWidget {
  const CropImage({
    super.key,
    required this.slug,
    required this.category,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String slug;
  final String category;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/crops/$slug.jpg',
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, _, _) => _placeholder(),
    );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _placeholder() {
    final c = AppColors.categoryColor(category);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.22), c.withValues(alpha: 0.12)],
        ),
      ),
      child: Center(
        child: Icon(Icons.eco_rounded, color: c.withValues(alpha: 0.55), size: 34),
      ),
    );
  }
}
