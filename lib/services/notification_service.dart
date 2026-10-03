import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// The daily writing reminder.
///
/// The reminder state lives in the settings box so the switch in Settings and
/// the schedule the OS holds can never disagree after a restart.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _dailyReminderId = 0;
  static const enabledKey = 'reminder_enabled';
  static const hourKey = 'reminder_hour';
  static const minuteKey = 'reminder_minute';
  static const titleKey = 'reminder_title';
  static const bodyKey = 'reminder_body';
  static const defaultHour = 20;
  static const defaultMinute = 0;

  static Future<void> init() async {
    tz.initializeTimeZones();
    // Without this `tz.local` is UTC and the reminder arrives at the wrong
    // hour everywhere outside Greenwich.
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (error) {
      debugPrint('Local time zone unavailable, reminders use UTC: $error');
    }
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // Permission is asked when the user turns the reminder on, not at launch.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
  }

  static Box get _settings => Hive.box('settings');

  static bool get isEnabled =>
      _settings.get(enabledKey, defaultValue: false) == true;

  static int get hour {
    final value = _settings.get(hourKey);
    return value is int ? value : defaultHour;
  }

  static int get minute {
    final value = _settings.get(minuteKey);
    return value is int ? value : defaultMinute;
  }

  /// Asks the OS for permission to post notifications. Android 13+ and iOS
  /// both refuse silently without it.
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
      return false;
    }
    return true;
  }

  /// Turns the reminder on at [hour]:[minute] with already localized text,
  /// and remembers all of it so it can be rescheduled on the next launch.
  static Future<void> enableDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _settings.putAll({
      enabledKey: true,
      hourKey: hour,
      minuteKey: minute,
      titleKey: title,
      bodyKey: body,
    });
    await _schedule(hour: hour, minute: minute, title: title, body: body);
  }

  static Future<void> disableDailyReminder() async {
    await _settings.put(enabledKey, false);
    await _plugin.cancel(_dailyReminderId);
  }

  /// Re-applies the stored reminder. Called on launch so a changed time zone
  /// or a reinstall of the plugin state never leaves the switch lying.
  static Future<void> restoreScheduledReminder() async {
    if (!isEnabled) return;
    final title = _settings.get(titleKey);
    final body = _settings.get(bodyKey);
    if (title is! String || body is! String) return;
    try {
      await _schedule(hour: hour, minute: minute, title: title, body: body);
    } catch (error) {
      debugPrint('Daily reminder could not be rescheduled: $error');
    }
  }

  static Future<void> _schedule({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) {
    return _plugin.zonedSchedule(
      _dailyReminderId,
      title,
      body,
      _next(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'journal_reminder',
          'Journal Reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact needs no special permission; a journal reminder a few minutes
      // late is fine, and exact alarms are reserved for alarm-clock apps.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _next(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var value =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (value.isBefore(now)) value = value.add(const Duration(days: 1));
    return value;
  }
}
