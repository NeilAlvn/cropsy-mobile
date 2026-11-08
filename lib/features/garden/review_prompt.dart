/// The native "rate this app" request, asked after something went well.
///
/// PRD amendment 2026-11-08: §3 and §4 said "no in-app review prompt". Luuk
/// reversed that because 0 ratings hold back store ranking. What keeps it fair:
/// only the OS sheet (no "do you like us?" gate in front of it), only after a
/// win, and rarely. Apple and Google apply their own quotas on top, and either
/// may silently show nothing.
library;

import 'package:in_app_review/in_app_review.dart';

import '../../analytics/analytics.dart';
import 'garden_repository.dart';

class ReviewPrompt {
  static const _winsKey = 'review_wins';
  static const _firstWinKey = 'review_first_win';
  static const _lastAskKey = 'review_last_ask';

  /// A logged step counts 1. A harvest is the payoff, so it clears the bar alone.
  static const stepWin = 1;
  static const harvestWin = 3;

  static const _winsNeeded = 3;
  static const _minDaysUsed = 3;
  static const _daysBetweenAsks = 120;

  static bool shouldAsk({
    required DateTime now,
    required int wins,
    required DateTime firstWin,
    DateTime? lastAsk,
  }) {
    if (wins < _winsNeeded) return false;
    if (now.difference(firstWin).inDays < _minDaysUsed) return false;
    return lastAsk == null || now.difference(lastAsk).inDays >= _daysBetweenAsks;
  }

  /// Call after a win. Never throws: a rating request must not break logging.
  static Future<void> recordWin(GardenRepository repo, int weight, {DateTime? at}) async {
    try {
      final now = at ?? DateTime.now();
      final wins = (int.tryParse(await repo.meta(_winsKey) ?? '') ?? 0) + weight;
      await repo.setMeta(_winsKey, '$wins');
      var first = DateTime.tryParse(await repo.meta(_firstWinKey) ?? '');
      if (first == null) {
        first = now;
        await repo.setMeta(_firstWinKey, now.toIso8601String());
      }
      final last = DateTime.tryParse(await repo.meta(_lastAskKey) ?? '');
      if (!shouldAsk(now: now, wins: wins, firstWin: first, lastAsk: last)) return;

      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      // Only count it once it is really requested, or an unavailable store
      // would use up the 120 days.
      await repo.setMeta(_lastAskKey, now.toIso8601String());
      await repo.setMeta(_winsKey, '0');
      Analytics.capture('review_prompt_requested');
      await review.requestReview();
    } catch (_) {
      // Nothing to tell the gardener; the next win tries again.
    }
  }
}
