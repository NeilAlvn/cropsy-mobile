/// Shape and elevation — VisionTech base sections 5 and 6.
///
/// Three structural radii plus one for sheets, and nothing else. Content is
/// flat: cards, tiles and rows carry no shadow and no border, because a white
/// surface on the grey canvas is already the edge. Only things that float over
/// content (tab bar, sheets, toasts, icon buttons over media) cast a shadow.
///
/// (Filename/class kept as `Neo` so imports across the app do not churn.)
library;

import 'package:flutter/material.dart';

import 'colors.dart';

abstract final class Neo {
  /// Base 5 `radius-card`. Cards, dialogs, grouped list containers.
  static const double radius = 20;

  /// Image tiles, thumbnails, inputs, skeletons.
  static const double radiusTile = 16;

  /// Buttons, chips, badges, search fields, the tab bar.
  static const double radiusPill = 999;

  /// Top corners of bottom sheets and full-screen modals.
  static const double radiusSheet = 28;

  /// Small images inside a row (40 to 56 wide).
  static const double radiusThumb = 12;

  static const double borderWidth = 1;

  /// Hairline ring. Inputs, ghost buttons, dividers — not cards.
  ///
  /// A getter, not a `static final`: a field would bake in whichever scheme
  /// happened to be live the first time something drew a border, and then keep
  /// drawing the light hairline all night.
  static Border get border => Border.fromBorderSide(
        BorderSide(color: AppColors.hairline, width: borderWidth),
      );

  /// Elevation is light falling past an edge, so the scheme decides how much
  /// of it there is to block. The light column's 10% ink over a bright canvas
  /// is a soft drop; the same ink over `canvas` at 0xFF121712 moves almost no
  /// pixels, which is how the tab bar and the sheets lost their lift in dark.
  /// Dark pays for a near-black canvas with a deeper, untinted shadow.
  static Color _shadow(int lightArgb, int darkArgb) =>
      Color(AppColors.isDark ? darkArgb : lightArgb);

  /// Level 1, floating: tab bar, icon buttons over media, toasts.
  static List<BoxShadow> get float => [
        BoxShadow(
          color: _shadow(0x1A17191C, 0x66000000),
          offset: const Offset(0, 8),
          blurRadius: 24,
        ),
      ];

  /// Level 2, overlay: bottom sheets, dialogs, popovers.
  static List<BoxShadow> get overlay => [
        BoxShadow(
          color: _shadow(0x2417191C, 0x8A000000),
          offset: const Offset(0, 16),
          blurRadius: 40,
        ),
      ];

  /// Legacy names, mapped onto the two levels above.
  static List<BoxShadow> get shadow => float;
  static List<BoxShadow> get shadowSm => float;

  /// Standard surface: a flat white card by default. Pass `shadowed: true`
  /// only for something that genuinely floats over content.
  static BoxDecoration box({
    Color? color,
    double r = radius,
    bool shadowed = false,
    bool bordered = false,
    List<BoxShadow>? shadowOverride,
  }) =>
      BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(r),
        border: bordered ? border : null,
        boxShadow: shadowed ? (shadowOverride ?? float) : null,
      );
}
