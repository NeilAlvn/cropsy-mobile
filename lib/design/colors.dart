/// Cropsy colour tokens — VisionTech Design System v0.6 (the base Nime and
/// Farmsy ship), with Cropsy's brand slots filled, in both schemes.
///
/// Brand slot decisions (section 12 of the base):
/// - `accent` is a grass green, picked against the reference Luuk chose. The
///   terracotta the app started on is now the mascot's pot and the warm note in
///   the art ([AppColors.clayWarm]), not the interface colour.
/// - `accent` is text-safe: white on it clears 4.5:1, which the reference's own
///   brighter green does not. `accentBright` carries that vividness wherever
///   nothing has to be read on top of it: node buttons, the sky, art.
/// - Green doubles as the positive semantic here, so a verdict never renders as
///   a bare green fill: it keeps its icon and its label (base 10).
///
/// Screens read these as `AppColors.ink` and the like. They are getters over
/// the active [AppPalette], not constants, so the whole app answers a theme
/// change by rebuilding rather than by threading a palette through every
/// widget. [AppColors.scheme] is what flips them; `main.dart` drives it from
/// the platform brightness and the user's setting.
library;

import 'package:flutter/material.dart';

/// One scheme's worth of colour. Two exist: [AppPalette.light] and
/// [AppPalette.dark].
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.tile,
    required this.hairline,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.inkPlaceholder,
    required this.onInk,
    required this.scrim,
    required this.accent,
    required this.accentDeep,
    required this.onAccent,
    required this.accentBright,
    required this.forest,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.skyTop,
    required this.skyMid,
    required this.positive,
    required this.warning,
    required this.critical,
    required this.positiveSoft,
    required this.warningSoft,
    required this.criticalSoft,
    required this.onSemantic,
    required this.amber,
    required this.amberDeep,
    required this.amberSoft,
    required this.onAmber,
  });

  final Brightness brightness;

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color tile;
  final Color hairline;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color inkPlaceholder;
  final Color onInk;
  final Color scrim;

  final Color accent;
  final Color accentDeep;
  final Color onAccent;
  final Color accentBright;
  final Color forest;
  final Color accentSoft;
  final Color onAccentSoft;
  final Color skyTop;
  final Color skyMid;

  final Color positive;
  final Color warning;
  final Color critical;
  final Color positiveSoft;
  final Color warningSoft;
  final Color criticalSoft;
  final Color onSemantic;

  final Color amber;
  final Color amberDeep;
  final Color amberSoft;
  final Color onAmber;

  static const light = AppPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFF3F7EE),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    tile: Color(0xFFEAF0E4),
    hairline: Color(0x1417191C),
    ink: Color(0xFF16211A),
    inkMuted: Color(0xFF576055),
    inkFaint: Color(0xFF6A7368),
    inkPlaceholder: Color(0xFF8B958A),
    onInk: Color(0xFFFFFFFF),
    scrim: Color(0x66101114),
    accent: Color(0xFF2A7F2A),
    accentDeep: Color(0xFF1F6420),
    onAccent: Color(0xFFFFFFFF),
    accentBright: Color(0xFF4CC23F),
    forest: Color(0xFF15391D),
    accentSoft: Color(0xFFE2F3D8),
    onAccentSoft: Color(0xFF22641F),
    skyTop: Color(0xFFD8F0A8),
    skyMid: Color(0xFFEFF8DE),
    positive: Color(0xFF137A4A),
    warning: Color(0xFF9A5B00),
    critical: Color(0xFFC0292B),
    positiveSoft: Color(0xFFE4F3EA),
    warningSoft: Color(0xFFFBEFD9),
    criticalSoft: Color(0xFFFBE5E5),
    onSemantic: Color(0xFFFFFFFF),
    amber: Color(0xFFE8B33A),
    amberDeep: Color(0xFFB9821A),
    amberSoft: Color(0xFFF7E7BE),
    onAmber: Color(0xFF3A2A06),
  );

  /// Base 3.2's dark column, tuned the way the light one was: the canvas keeps
  /// a trace of leaf, the accent lifts until it carries text on a dark ground
  /// (white no longer would), and the sky becomes the night version of the same
  /// gradient rather than a grey.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    canvas: Color(0xFF121712),
    surface: Color(0xFF1A201A),
    surfaceRaised: Color(0xFF222922),
    tile: Color(0xFF232B23),
    hairline: Color(0x1AFFFFFF),
    ink: Color(0xFFF2F5F0),
    inkMuted: Color(0xFFAFBAAD),
    inkFaint: Color(0xFF8B958A),
    inkPlaceholder: Color(0xFF6A7368),
    onInk: Color(0xFF121712),
    scrim: Color(0x99000000),
    accent: Color(0xFF63C455),
    accentDeep: Color(0xFF4CA742),
    onAccent: Color(0xFF0C1A0C),
    accentBright: Color(0xFF6FD45F),
    forest: Color(0xFF0E2A13),
    accentSoft: Color(0xFF23361F),
    onAccentSoft: Color(0xFF9FDD92),
    skyTop: Color(0xFF1C2A16),
    skyMid: Color(0xFF161E14),
    positive: Color(0xFF3DBE72),
    warning: Color(0xFFF2B544),
    critical: Color(0xFFF0605F),
    positiveSoft: Color(0x283DBE72),
    warningSoft: Color(0x28F2B544),
    criticalSoft: Color(0x28F0605F),
    onSemantic: Color(0xFF101114),
    amber: Color(0xFFE8B33A),
    amberDeep: Color(0xFFA9760F),
    amberSoft: Color(0xFF3A2E12),
    onAmber: Color(0xFF14100A),
  );
}

abstract final class AppColors {
  /// The scheme every token below reads. Rebuilding on this is `main.dart`'s
  /// job; nothing else should listen to it.
  static final scheme = ValueNotifier<AppPalette>(AppPalette.light);

  static AppPalette get palette => scheme.value;
  static bool get isDark => palette.brightness == Brightness.dark;

  // ---------------------------------------------------------------- neutrals
  /// Screen background. Base 3.2 `canvas`.
  static Color get canvas => palette.canvas;

  /// Cards, sheets, dialogs. Base 3.2 `surface`.
  static Color get surface => palette.surface;
  static Color get surfaceRaised => palette.surfaceRaised;

  /// Image tiles, grouped row containers, input fills, skeletons.
  static Color get tile => palette.tile;

  /// Borders, dividers, rings. Never on a card: the surface is the edge.
  static Color get hairline => palette.hairline;

  static Color get ink => palette.ink;
  static Color get inkMuted => palette.inkMuted;
  static Color get inkFaint => palette.inkFaint;
  static Color get inkPlaceholder => palette.inkPlaceholder;
  static Color get onInk => palette.onInk;
  static Color get scrim => palette.scrim;

  // ------------------------------------------------------------------- brand
  static Color get accent => palette.accent;
  static Color get accentDeep => palette.accentDeep;
  static Color get onAccent => palette.onAccent;

  /// Fills only, never under text.
  static Color get accentBright => palette.accentBright;

  /// The dark ground under banners and the splash.
  static Color get forest => palette.forest;
  static Color get accentSoft => palette.accentSoft;
  static Color get onAccentSoft => palette.onAccentSoft;

  /// The season path's sky, top to bottom.
  static Color get skyTop => palette.skyTop;
  static Color get skyMid => palette.skyMid;

  // --------------------------------------------------------------- semantics
  static Color get positive => palette.positive;
  static Color get warning => palette.warning;
  static Color get critical => palette.critical;
  static Color get positiveSoft => palette.positiveSoft;
  static Color get warningSoft => palette.warningSoft;
  static Color get criticalSoft => palette.criticalSoft;
  static Color get onSemantic => palette.onSemantic;

  /// The season path's month markers.
  static Color get amber => palette.amber;
  static Color get amberDeep => palette.amberDeep;
  static Color get amberSoft => palette.amberSoft;
  static Color get onAmber => palette.onAmber;

  // Functional fills: rings, bars, dots, meters. Not text-safe on light, and
  // the same in both schemes by design (base 3.4).
  static const vividPositive = Color(0xFF79FB32);
  static const vividWarning = Color(0xFFF2812F);
  static const vividCritical = Color(0xFFCE1A3B);
  static const onVivid = Color(0xFF101114);

  /// Terracotta survives as the mascot's pot and the warm note in the art, so
  /// it keeps a token even though it is no longer the accent.
  static const clayWarm = Color(0xFFB4532F);

  // ------------------------------------------------------- legacy aliases
  // The old Cropsy names, kept so the screens keep compiling while they move to
  // the token names above. Delete an alias once its callers move.
  static Color get sprout => accent;
  static Color get sproutDeep => accentDeep;
  static const clay = clayWarm;
  static const clayDeep = Color(0xFF93401F);
  static Color get paper => canvas;
  static Color get sand => tile;
  static Color get muted => inkMuted;
  static Color get border => hairline;
  static const lemon = vividWarning;
  static Color get sky => inkMuted;

  // Weather hints (F4). The base allows no fourth semantic hue, so rain reads
  // as information in `ink` and only heat and frost carry a semantic.
  static Color get rain => ink;
  static Color get heat => warning;
  static Color get frost => inkMuted;

  // Planting-calendar lanes. Data colours, one hue per activity.
  static const bandSowIndoor = Color(0xFFBFE0A6);
  static const bandSowOutdoor = Color(0xFF63B36B);
  static const bandPlantOut = Color(0xFF137A4A);
  static const bandHarvest = clayWarm;

  // Difficulty and status map onto the fixed semantics.
  static Color get easy => positive;
  static Color get medium => warning;
  static Color get hard => critical;
  static Color get done => positive;
  static Color get warn => critical;

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
