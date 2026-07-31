/// Cropsy colour tokens — a fresh identity, deliberately unlike Farmsy's muted
/// forest-green + cream. Concept: hands-in-soil, calm competence. Sprout green +
/// terracotta clay (the container motif) on warm paper.
///
/// First pass — expected to evolve once Luuk reacts to the prototype.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const sprout = Color(0xFF5C8A3A); // primary — alive leaf green
  static const sproutDeep = Color(0xFF44692A); // pressed / deep accents
  static const clay = Color(0xFFC56A45); // accent — terracotta pot
  static const clayDeep = Color(0xFFA9542F);

  // Surfaces
  static const paper = Color(0xFFF7F6F1); // app background
  static const sand = Color(0xFFEFEBE0); // cards / sections
  static const surface = Color(0xFFFFFFFF);

  // Text
  static const ink = Color(0xFF1E1B16); // primary text (warm near-black)
  static const muted = Color(0xFF6E6A61); // secondary / captions
  static const hairline = Color(0xFFE4DFD3); // dividers / borders

  // Modern × natural tokens — soft hairline outlines + diffused elevation.
  // `border` is a warm light hairline (not a bold outline) for a calm, clean feel.
  static const border = Color(0xFFDDD6C8); // soft hairline outline on surfaces
  static const lemon = Color(0xFFEAB93F); // warm accent — banners, highlights
  static const sky = Color(0xFF74A9C7); // secondary pop

  // Weather accents (F4 hint badges)
  static const rain = Color(0xFF4A7BA6);
  static const heat = Color(0xFFE8A13A);
  static const frost = Color(0xFF8FB0C7);

  // Planting-calendar band colours (per activity lane)
  static const bandSowIndoor = Color(0xFFA9CE8B); // pale sprout
  static const bandSowOutdoor = Color(0xFF6DA544); // green
  static const bandPlantOut = Color(0xFF44692A); // deep green
  static const bandHarvest = Color(0xFFC56A45); // clay

  // Difficulty
  static const easy = Color(0xFF5C8A3A);
  static const medium = Color(0xFFE8A13A);
  static const hard = Color(0xFFC0392B);

  // Status
  static const done = Color(0xFF5C8A3A);
  static const warn = Color(0xFFC0392B);

  /// Category dot colours, keyed by the crop `category` field (9 categories).
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
      AppColors.category[category] ?? muted;
}
