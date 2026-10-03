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
  static const _weeklyReviewId = 1;
  static const weeklyEnabledKey = 'weekly_review_enabled';
  static const weeklyTitleKey = 'weekly_review_title';
  static const weeklyBodyKey = 'weekly_review_body';
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
    if (isWeeklyReviewEnabled) {
      final title = _settings.get(weeklyTitleKey);
      final body = _settings.get(weeklyBodyKey);
      if (title is String && body is String) {
        try {
          await _scheduleWeekly(title, body);
        } catch (error) {
          debugPrint('Weekly review could not be rescheduled: $error');
        }
      }
    }
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

  // ─── Letters to the future ─────────────────────────────────────────────

  /// A stable notification id per letter, clear of the fixed ids above.
  static int letterNotificationId(String letterId) {
    var hash = 0;
    for (final unit in letterId.codeUnits) {
      hash = (hash * 31 + unit) & 0x3fffffff;
    }
    return 1000 + hash % 1000000;
  }

  /// Announces a letter to the future on the day it opens. The text is
  /// generic so the lock screen never shows what was written.
  static Future<void> scheduleLetterUnlock({
    required String letterId,
    required DateTime opensAt,
    required String title,
    required String body,
  }) async {
    final when = tz.TZDateTime(
      tz.local,
      opensAt.year,
      opensAt.month,
      opensAt.day,
      9,
    );
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        letterNotificationId(letterId),
        title,
        body,
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'letters',
            'Letters to the future',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (error) {
      debugPrint('Letter notification not scheduled: $error');
    }
  }

  static Future<void> cancelLetterUnlock(String letterId) =>
      _plugin.cancel(letterNotificationId(letterId));

  // ─── Weekly review ─────────────────────────────────────────────────────

  static bool get isWeeklyReviewEnabled =>
      _settings.get(weeklyEnabledKey, defaultValue: false) == true;

  /// Every Sunday evening: the week's pulse is ready to read.
  static Future<void> enableWeeklyReview({
    required String title,
    required String body,
  }) async {
    await _settings.putAll({
      weeklyEnabledKey: true,
      weeklyTitleKey: title,
      weeklyBodyKey: body,
    });
    await _scheduleWeekly(title, body);
  }

  static Future<void> disableWeeklyReview() async {
    await _settings.put(weeklyEnabledKey, false);
    await _plugin.cancel(_weeklyReviewId);
  }

  static Future<void> _scheduleWeekly(String title, String body) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18);
    while (when.weekday != DateTime.sunday || !when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return _plugin.zonedSchedule(
      _weeklyReviewId,
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_review',
          'Weekly review',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
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
