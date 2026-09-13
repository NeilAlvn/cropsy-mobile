/// Prototype seed constants — the demo owner, the demo "today", and the starter
/// crops used by onboarding's pre-checked picks and the "skip with a demo
/// garden" shortcut.
///
/// `demoToday` is a fixed spring date so "This Week" shows a rich mix (sow /
/// plant-out / water) with weather hints, rather than whatever the real calendar
/// happens to be. Production uses the real clock — this is prototype scaffolding.
library;

const demoToday = '2026-05-13';

/// Container-friendly starters, pre-checked in onboarding.
const starterCrops = <String, int>{
  'tomato': 12,
  'lettuce': 7,
  'basil': 3,
  'courgette': 20,
  'carrot': 10,
};
