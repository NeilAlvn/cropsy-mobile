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
  /// Screen background. Base 3.2 `canvas`, warmed a touch toward the leaf.
  static const canvas = Color(0xFFF3F7EE);

  /// Cards, sheets, dialogs. Base 3.2 `surface`.
  static const surface = Color(0xFFFFFFFF);

  /// Image tiles, grouped row containers, input fills, skeletons.
  static const tile = Color(0xFFEAF0E4);

  /// Borders, dividers, rings. Never on a card: white on canvas is the edge.
  static const hairline = Color(0x1417191C);

  static const ink = Color(0xFF16211A);
  static const inkMuted = Color(0xFF576055);
  static const inkFaint = Color(0xFF6A7368);
  static const inkPlaceholder = Color(0xFF8B958A);
  static const onInk = Color(0xFFFFFFFF);
  static const scrim = Color(0x66101114);

  // ------------------------------------------------------------------- brand
  /// Base 3.3 `accent`. Grass green, 5.0:1 against white.
  static const accent = Color(0xFF2A7F2A);

  /// Pressed and deep accents.
  static const accentDeep = Color(0xFF1F6420);
  static const onAccent = Color(0xFFFFFFFF);

  /// The reference's vivid green. Fills only, never under text: node buttons,
  /// the sky gradient, illustration. Fails as a text ground on purpose.
  static const accentBright = Color(0xFF4CC23F);

  /// The dark ground of the reference: month bars, banners, the splash.
  static const forest = Color(0xFF15391D);

  /// Accent at ~12 percent over canvas. Selected rows, highlight cards.
  static const accentSoft = Color(0xFFE2F3D8);

  /// Text on [accentSoft], 4.5:1.
  static const onAccentSoft = Color(0xFF22641F);

  /// The season path's month markers. Amber keeps a month from reading as one
  /// more task: the green discs are things to do, these are where you are.
  /// The chest's gold is the same family.
  static const amber = Color(0xFFE8B33A);
  static const amberDeep = Color(0xFFB9821A);
  static const amberSoft = Color(0xFFF7E7BE);
  static const onAmber = Color(0xFF3A2A06);

  /// The path's sky, top to bottom.
  static const skyTop = Color(0xFFD8F0A8);
  static const skyMid = Color(0xFFEFF8DE);

  /// Terracotta survives as the mascot's pot and the warm note in art, so it
  /// keeps a token even though it is no longer the accent.
  static const clayWarm = Color(0xFFB4532F);

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
  static const clay = clayWarm;
  static const clayDeep = Color(0xFF93401F);
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
  static const bandHarvest = clayWarm;

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
