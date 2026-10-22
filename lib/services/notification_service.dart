import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const int _dailyId = 1001;
  static const int _dailyIdBaseV2 = 1100;
  static const String _channelId = 'daily_reminder';
  static const String _channelName = 'Daily reminders';

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      final String name = (tzInfo is String) ? tzInfo : (tzInfo?.name as String? ?? tzInfo.toString());
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      if (kDebugMode) {
        // If timezone can't be resolved, scheduling will fallback to tz.local default.
        debugPrint('Failed to set local timezone: $e');
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher_diary');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Daily reminder notifications',
        importance: Importance.defaultImportance,
      ),
    );

    _initialized = true;
  }

  static Future<bool> requestPermissionIfNeeded() async {
    await ensureInitialized();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? true; // pre-Android 13 returns null; treat as granted
  }

  static Future<void> cancelDailyReminder() async {
    await ensureInitialized();
    await _plugin.cancel(_dailyId);
  }

  static Future<void> cancelDailyRemindersV2({required int count}) async {
    await ensureInitialized();
    // Also cancel legacy single reminder.
    await _plugin.cancel(_dailyId);
    for (var i = 0; i < count; i++) {
      await _plugin.cancel(_dailyIdBaseV2 + i);
    }
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await ensureInitialized();

    final scheduled = _nextInstanceOfTime(hour: hour, minute: minute);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Daily reminder notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher_diary',
      ),
    );

    await _plugin.zonedSchedule(
      _dailyId,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleDailyReminderV2({
    required int index,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await ensureInitialized();
    final scheduled = _nextInstanceOfTime(hour: hour, minute: minute);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Daily reminder notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher_diary',
      ),
    );
    await _plugin.zonedSchedule(
      _dailyIdBaseV2 + index,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showNow({
    required String title,
    required String body,
  }) async {
    await ensureInitialized();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Daily reminder notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher_diary',
      ),
    );
    await _plugin.show(9999, title, body, details);
  }

  static tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

