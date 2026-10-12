/// Lifecycle notifications: trial reminders and seasonal offers.
///
/// Separate from [Reminders] (daily care), which cancels and re-schedules its
/// own ids on every repository change. Lifecycle ids live in their own range
/// (1000+) so that never wipes them.
library;

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/strings.dart';
import '../timing/types.dart';

class Lifecycle {
  // The plugin is a singleton; this is the same instance Reminders set up.
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(),
    android: AndroidNotificationDetails('account', 'Trial & offers', importance: Importance.defaultImportance),
  );

  static const _trialNudge = 1000;
  static const _trialEnds = 1001;
  static const _autumn = 1010;
  static const _spring = 1011;

  /// Tapping a seasonal nudge opens the paywall from the home card's door.
  static const paywallPayload = 'paywall:homeCard';

  /// Day 3 and day 5 of a trial that started on [startedOn], at 09:00 local.
  static ({DateTime nudge, DateTime ends}) trialTimes(DateTime startedOn) => (
    nudge: DateTime(startedOn.year, startedOn.month, startedOn.day + 3, 9),
    ends: DateTime(startedOn.year, startedOn.month, startedOn.day + 5, 9),
  );

  /// The next [month]/[day] at [hour] strictly after [now]: this year's if it
  /// is still ahead, otherwise next year's. One fixed id per nudge, re-aimed
  /// here on every launch, is what keeps it to once a year.
  static DateTime nextYearly(DateTime now, int month, int day, {int hour = 10}) {
    final at = DateTime(now.year, month, day, hour);
    return at.isAfter(now) ? at : DateTime(now.year + 1, month, day, hour);
  }

  /// A yearly trial just started on [startedOn]. Schedules the value nudge on
  /// day 3 and the honest "ends in 2 days" reminder on day 5.
  static Future<void> scheduleTrialReminders(DateTime startedOn, {String lang = 'en'}) async {
    final t = trialTimes(startedOn);
    // ponytail: generic day-3 copy; naming a real upcoming task needs the repo
    // passed in, add it if the nudge underperforms.
    await _at(_trialNudge, t.nudge, Str.trialPlanReadyTitle, Str.trialPlanReadyBody, lang);
    await _at(_trialEnds, t.ends, Str.trialEndsTitle,
        Platform.isAndroid ? Str.trialEndsBodyAndroid : Str.trialEndsBodyIos, lang);
  }

  /// The person bought or the trial ended: drop any pending trial reminders.
  static Future<void> cancelTrialReminders() async {
    await _plugin.cancel(id: _trialNudge);
    await _plugin.cancel(id: _trialEnds);
  }

  /// Seasonal nudges for free gardeners: "plan next season" on 1 October and
  /// "season starts" on 15 February, 10:00. Safe to call on every launch and
  /// resume; premium or no permission clears them.
  static Future<void> syncSeasonal({required bool premium, String lang = 'en'}) async {
    if (premium || !await _permitted()) {
      await _plugin.cancel(id: _autumn);
      await _plugin.cancel(id: _spring);
      return;
    }
    final now = DateTime.now();
    await _at(_autumn, nextYearly(now, 10, 1), Str.nudgeAutumnTitle, Str.nudgeAutumnBody, lang, payload: paywallPayload);
    await _at(_spring, nextYearly(now, 2, 15), Str.nudgeSpringTitle, Str.nudgeSpringBody, lang, payload: paywallPayload);
  }

  static Future<bool> _permitted() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.areNotificationsEnabled() ?? false;
    return false;
  }

  static Future<void> _at(int id, DateTime at, LocalizedText title, LocalizedText body, String lang,
      {String? payload}) async {
    if (!at.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title.pick(lang),
      body: body.pick(lang),
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }
}
