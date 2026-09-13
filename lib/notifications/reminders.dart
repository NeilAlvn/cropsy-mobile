/// Local reminders (PRD 5.6): one notification per day at 08:00 for the next
/// seven days, summarising that day's tasks. Re-scheduled whenever the
/// repository changes. No push, no server — offline is the default.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/garden/garden_repository.dart';
import '../timing/dates.dart';

class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(),
    android: AndroidNotificationDetails('care', 'Care reminders', importance: Importance.defaultImportance),
  );

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  /// Asked after the first task is shown (PRD 1.8), never on launch.
  static Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    return false;
  }

  /// Replace every scheduled reminder with the next seven days of items.
  static Future<void> schedule(List<ThisWeekItem> items, {required String today, int hour = 8}) async {
    await _plugin.cancelAll();
    final byDay = <String, List<ThisWeekItem>>{};
    for (final i in items) {
      if (i.completed || i.due.compareTo(today) < 0) continue;
      byDay.putIfAbsent(i.due, () => []).add(i);
    }
    var id = 0;
    for (final day in byDay.keys.toList()..sort()) {
      final d = parseIso(day);
      final at = DateTime(d.year, d.month, d.day, hour);
      if (!at.isAfter(DateTime.now())) continue;
      final list = byDay[day]!;
      final body = list.map((i) => '${_verb(i)} ${i.cropName.toLowerCase()}').take(4).join(', ');
      await _plugin.zonedSchedule(
        id: id++,
        title: list.length == 1 ? 'One thing to do today' : '${list.length} things to do today',
        body: body,
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  static String _verb(ThisWeekItem i) => switch (i.kind.name) {
        'water' => 'Water',
        'sow' => 'Sow',
        'transplant' => 'Plant out',
        'harvest' => 'Harvest',
        'feed' => 'Feed',
        'potOn' => 'Pot on',
        'thin' => 'Thin',
        _ => 'Check',
      };
}
