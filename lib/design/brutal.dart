/// Modernist building blocks: hairline outlines + soft diffused elevation,
/// generously rounded corners. Every boxy surface in Cropsy is built from these
/// so the look stays consistent — cards, buttons, chips, tabs, tiles.
///
/// (Filename/class kept as `Neo` to avoid churn across imports; the values are
/// now a calm modern × natural language, not neo-brutalism.)
library;

import 'package:flutter/material.dart';

import 'colors.dart';

abstract final class Neo {
  static const double radius = 16;
  static const double borderWidth = 1;

  static const Border border = Border.fromBorderSide(
    BorderSide(color: AppColors.hairline, width: borderWidth),
  );

  /// Soft, diffused elevation — a gentle drop plus a tight ambient shadow.
  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 8), blurRadius: 20),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// A lighter lift for dense elements (list rows, chips).
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x12000000), offset: Offset(0, 4), blurRadius: 12),
  ];

  /// Standard surface: fill + hairline outline + soft elevation.
  static BoxDecoration box({
    Color color = AppColors.surface,
    double r = radius,
    bool shadowed = true,
    List<BoxShadow>? shadowOverride,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r),
        border: border,
        boxShadow: shadowed ? (shadowOverride ?? shadow) : null,
      );
}
