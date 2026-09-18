/// Product analytics (PostHog, EU cloud).
///
/// PRD amendment 2026-09-18: §5.9 used to say "no telemetry beyond RevenueCat
/// and Sentry". Analytics is in, under three rules that keep the privacy
/// promise honest:
///
/// 1. **Consent first.** The SDK is not initialised until the person says yes.
///    No answer, or no, means `setup()` is never called, so nothing is
///    collected, queued or sent — not even an anonymous id.
/// 2. **Counts, not content.** Events carry a crop slug or a count at most.
///    No notes, no photos, no postcode, no free text.
/// 3. **Ours only.** First-party, EU ingest, no ad SDK, no cross-app tracking,
///    so no ATT prompt (PRD §5.9 keeps that promise).
library;

import 'package:posthog_flutter/posthog_flutter.dart';

import '../config.dart';

class Analytics {
  /// `app_meta` key. 'yes' / 'no' / absent = never asked.
  static const metaKey = 'analytics_consent';

  static bool _live = false;

  /// True once the SDK is running, i.e. consent given and a key configured.
  static bool get live => _live;

  /// Boot with the stored answer. Anything but a stored 'yes' is a no-op.
  static Future<void> init(String? consent) async {
    if (consent == 'yes') await _start();
  }

  /// The answer changed in Settings (or the first-run ask).
  ///
  /// Turning it off stops collection and clears the local id, so the next
  /// opt-in is a new anonymous person rather than a resumed one.
  static Future<void> setConsent(bool yes) async {
    if (yes) {
      await _start();
      return;
    }
    if (!_live) return;
    await Posthog().disable();
    await Posthog().reset();
    _live = false;
  }

  static Future<void> _start() async {
    if (_live || posthogApiKey.isEmpty) return;
    final config = PostHogConfig(posthogApiKey)
      ..host = posthogHost
      // Opens and backgrounds: that is MAU and D7 (PRD §3), and it is the
      // reason we do not need an event on every screen.
      ..captureApplicationLifecycleEvents = true
      // Everything below is off on purpose. Replay would film someone's
      // garden; surveys are a pop-up we promised never to show; errors are
      // Sentry's job and paying twice for them helps nobody.
      ..sessionReplay = false
      ..surveys = false;
    config.errorTrackingConfig.captureFlutterErrors = false;
    await Posthog().setup(config);
    _live = true;
  }

  /// Follow the account, the same way RevenueCat does.
  static Future<void> identify(String uid) async {
    if (_live) await Posthog().identify(userId: uid);
  }

  static Future<void> signedOut() async {
    if (_live) await Posthog().reset();
  }

  /// One place that swallows "not consented" so call sites stay one-liners.
  static Future<void> capture(String event, {Map<String, Object>? properties}) async {
    if (_live) await Posthog().capture(eventName: event, properties: properties);
  }
}
