/// Neo-brutalist building blocks: hard black outlines + solid offset shadows
/// (zero blur), sharp-ish corners. Every boxy surface in Cropsy is built from
/// these so the look stays consistent — cards, buttons, chips, tabs, tiles.
library;

import 'package:flutter/material.dart';

import 'colors.dart';

abstract final class Neo {
  static const double radius = 6;
  static const double borderWidth = 2.5;
  static const Offset shadowOffset = Offset(4, 4);

  static const Border border = Border.fromBorderSide(
    BorderSide(color: AppColors.border, width: borderWidth),
  );

  /// The signature hard shadow — solid, no blur, offset down-right.
  static const List<BoxShadow> shadow = [
    BoxShadow(color: AppColors.border, offset: shadowOffset, blurRadius: 0),
  ];

  /// A smaller hard shadow for dense elements (list rows, chips).
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: AppColors.border, offset: Offset(3, 3), blurRadius: 0),
  ];

  /// Standard boxed surface: fill + black outline + hard shadow.
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
