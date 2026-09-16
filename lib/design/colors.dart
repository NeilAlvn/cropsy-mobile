/// Cropsy colour tokens — VisionTech Design System v0.6 (the base Nime and
/// Farmsy ship), with Cropsy's brand slots filled.
///
/// Brand slot decisions (section 12 of the base):
/// - `accent` is terracotta clay, the container motif. Nime and Farmsy are both
///   green, and in a garden app green already means "growing / good", so green
///   stays the fixed positive semantic and the accent takes the pot instead.
/// - Because the accent is not a semantic colour, the primary pill fills with
///   `accent` (base 8.1) and there is no separate vivid accent: the accent is
///   the functional control colour too.
/// - `canvas` is a warm neutral grey, within the 5 percent luminance the base
///   allows around its #F0F1F0 default. Cards are pure white and separate from
///   the ground by value, with no border.
///
/// Light theme only for now. Dark values are listed per token in the base; wire
/// them up when the app stops reading colours from static consts.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------- neutrals
  /// Screen background. Base 3.2 `canvas`.
  static const canvas = Color(0xFFF1F0EE);

  /// Cards, sheets, dialogs. Base 3.2 `surface`.
  static const surface = Color(0xFFFFFFFF);

  /// Image tiles, grouped row containers, input fills, skeletons.
  static const tile = Color(0xFFEDECE8);

  /// Borders, dividers, rings. Never on a card: white on canvas is the edge.
  static const hairline = Color(0x1417191C);

  static const ink = Color(0xFF17191C);
  static const inkMuted = Color(0xFF5C6068);
  static const inkFaint = Color(0xFF6B6F78);
  static const inkPlaceholder = Color(0xFF8A8E98);
  static const onInk = Color(0xFFFFFFFF);
  static const scrim = Color(0x66101114);

  // ------------------------------------------------------------------- brand
  /// Base 3.3 `accent`. Terracotta, 4.9:1 against white.
  static const accent = Color(0xFFB4532F);

  /// Pressed and deep accents.
  static const accentDeep = Color(0xFF93401F);
  static const onAccent = Color(0xFFFFFFFF);

  /// Accent at ~12 percent over canvas. Selected rows, highlight cards.
  static const accentSoft = Color(0xFFF3E4DC);

  /// Text on [accentSoft], 4.5:1.
  static const onAccentSoft = Color(0xFF8E3F22);

  // --------------------------------------------------------------- semantics
  // Fixed across every VisionTech app. Text-safe on canvas and tile.
  static const positive = Color(0xFF137A4A);
  static const warning = Color(0xFF9A5B00);
  static const critical = Color(0xFFC0292B);
  static const positiveSoft = Color(0xFFE4F3EA);
  static const warningSoft = Color(0xFFFBEFD9);
  static const criticalSoft = Color(0xFFFBE5E5);
  static const onSemantic = Color(0xFFFFFFFF);

  // Functional fills: rings, bars, dots, meters. Not text-safe on light.
  static const vividPositive = Color(0xFF79FB32);
  static const vividWarning = Color(0xFFF2812F);
  static const vividCritical = Color(0xFFCE1A3B);
  static const onVivid = Color(0xFF101114);

  // ------------------------------------------------------- legacy aliases
  // The old Cropsy names, kept so the 30-odd screens keep compiling while they
  // migrate to the token names above. Delete an alias once its callers move.
  static const sprout = accent;
  static const sproutDeep = accentDeep;
  static const clay = accent;
  static const clayDeep = accentDeep;
  static const paper = canvas;
  static const sand = tile;
  static const muted = inkMuted;
  static const border = hairline;
  static const lemon = vividWarning;
  static const sky = inkMuted;

  // Weather hints (F4). The base allows no fourth semantic hue, so rain reads
  // as information in `ink` and only heat and frost carry a semantic.
  static const rain = ink;
  static const heat = warning;
  static const frost = inkMuted;

  // Planting-calendar lanes. Data colours, one hue per activity.
  static const bandSowIndoor = Color(0xFFBFE0A6);
  static const bandSowOutdoor = Color(0xFF63B36B);
  static const bandPlantOut = Color(0xFF137A4A);
  static const bandHarvest = accent;

  // Difficulty and status map onto the fixed semantics.
  static const easy = positive;
  static const medium = warning;
  static const hard = critical;
  static const done = positive;
  static const warn = critical;

  /// Category dot colours, keyed by the crop `category` field (9 categories).
  /// Taxonomy colours, not brand: they label content the way a legend does.
  static const category = <String, Color>{
    'fruit': Color(0xFFD1495B),
    'fruit-veg': Color(0xFFE8743B),
    'herb': Color(0xFF5C8A3A),
    'root': Color(0xFFB07A3E),
    'legume': Color(0xFF7FA650),
    'brassica': Color(0xFF4E8D7C),
    'allium': Color(0xFF9B6FB0),
    'leafy': Color(0xFF6DA544),
    'potato': Color(0xFFC9A227),
  };

  static Color categoryColor(String category) =>
      AppColors.category[category] ?? inkMuted;
}
