/// Derived crop attributes the raw data doesn't carry yet — a prototype stand-in
/// so the GrowIt-style detail screen has a difficulty rating. Heuristic + a
/// curated override map for common crops. Replace with real data later.
library;

import '../timing/types.dart';

enum Difficulty { easy, medium, hard }

String difficultyLabel(Difficulty d) => switch (d) {
      Difficulty.easy => 'Easy',
      Difficulty.medium => 'Medium',
      Difficulty.hard => 'Hard',
    };

// Hand-set for the crops people actually start with, so those read right.
const _overrides = <String, Difficulty>{
  'lettuce': Difficulty.easy,
  'radish': Difficulty.easy,
  'rocket': Difficulty.easy,
  'basil': Difficulty.easy,
  'chives': Difficulty.easy,
  'mint': Difficulty.easy,
  'spinach': Difficulty.easy,
  'tomato': Difficulty.easy,
  'courgette': Difficulty.easy,
  'french-bean': Difficulty.easy,
  'pea': Difficulty.easy,
  'carrot': Difficulty.medium,
  'cauliflower': Difficulty.hard,
  'celeriac': Difficulty.hard,
  'melon': Difficulty.hard,
  'aubergine': Difficulty.hard,
  'asparagus': Difficulty.hard,
};

Difficulty difficultyOf(Crop crop) {
  // Real field first (PRD §8.1); the heuristic only covers a null.
  switch (crop.difficulty) {
    case 1:
      return Difficulty.easy;
    case 2:
      return Difficulty.medium;
    case 3:
      return Difficulty.hard;
  }
  final o = _overrides[crop.slug];
  if (o != null) return o;
  var score = 0;
  if (crop.frostTender) score++;
  if (crop.harvestDaysMax > 100) score++;
  if (crop.methods.any((m) => (m.minSoilC ?? 0) >= 12)) score++;
  if ((crop.minPotLitres ?? 0) >= 15) score++;
  if (score <= 0) return Difficulty.easy;
  if (score <= 2) return Difficulty.medium;
  return Difficulty.hard;
}
