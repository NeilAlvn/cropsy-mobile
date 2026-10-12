/// Local reminders (PRD 5.6): one notification per day at 08:00 for the next
/// seven days, summarising that day's tasks. Re-scheduled whenever the
/// repository changes. No push, no server — offline is the default.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../design/components.dart' show kindLine;
import '../features/garden/garden_repository.dart';
import '../l10n/strings.dart';
import '../timing/dates.dart';

class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(),
    android: AndroidNotificationDetails('care', 'Care reminders', importance: Importance.defaultImportance),
  );

  /// Care reminders own ids `0 .. careIds - 1`; everything above belongs to
  /// someone else (lifecycle uses 1000+) and survives a re-schedule.
  static const careIds = 100;
  static bool isCareId(int id) => id >= 0 && id < careIds;

  /// [onTap] gets the payload of a notification tapped while the app runs.
  static Future<void> init({void Function(String? payload)? onTap}) async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: onTap == null ? null : (r) => onTap(r.payload),
    );
  }

  /// The payload of the notification that cold-started the app, if one did.
  static Future<String?> launchPayload() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    return d?.didNotificationLaunchApp == true ? d?.notificationResponse?.payload : null;
  }

  /// Asked after the first task is shown (PRD 1.8), never on launch.
  static Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    return false;
  }

  /// Replace every scheduled care reminder with the next seven days of items.
  ///
  /// [lang] follows the profile's language: a notification is the one piece of
  /// the app that speaks while no screen is open, so it has to be told.
  static Future<void> schedule(
    List<ThisWeekItem> items, {
    required String today,
    String lang = 'en',
    int hour = 8,
  }) async {
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (isCareId(p.id)) await _plugin.cancel(id: p.id);
    }
    final byDay = <String, List<ThisWeekItem>>{};
    for (final i in items) {
      if (i.completed || i.due.compareTo(today) < 0) continue;
      byDay.putIfAbsent(i.due, () => []).add(i);
    }
    var id = 0;
    for (final day in byDay.keys.toList()..sort()) {
      final d = parseIso(day);
      final at = DateTime(d.year, d.month, d.day, hour);
      if (!at.isAfter(DateTime.now()) || !isCareId(id)) continue;
      final list = byDay[day]!;
      final body = list
          .map((i) {
            final crop = i.cropNames.pick(lang);
            final verb = kindLine(i.kind).pick(lang);
            // German puts the verb last and keeps the noun's capital: "Tomate gießen".
            // French reads as a label: "Tomate : arroser".
            return switch (lang) {
              'de' => '$crop ${verb.toLowerCase()}',
              'fr' => '$crop : ${verb.toLowerCase()}',
              _ => '$verb ${crop.toLowerCase()}',
            };
          })
          .take(4)
          .join(', ');
      await _plugin.zonedSchedule(
        id: id++,
        title: list.length == 1
            ? Str.reminderOneThing.pick(lang)
            : Str.reminderThings(list.length).pick(lang),
        body: body,
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

}
