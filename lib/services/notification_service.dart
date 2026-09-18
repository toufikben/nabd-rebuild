import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<void> init() async { tz.initializeTimeZones(); await _plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings())); }
  static Future<void> scheduleDailyReminder({required int hour, required int minute}) => _plugin.zonedSchedule(0, 'Time to write', 'Capture your thoughts for today', _next(hour, minute), const NotificationDetails(android: AndroidNotificationDetails('journal_reminder', 'Journal Reminder', importance: Importance.high, priority: Priority.high), iOS: DarwinNotificationDetails()), androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, matchDateTimeComponents: DateTimeComponents.time);
  static tz.TZDateTime _next(int hour, int minute) { final now = tz.TZDateTime.now(tz.local); var value = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute); if (value.isBefore(now)) value = value.add(const Duration(days: 1)); return value; }
  static Future<void> cancelAll() => _plugin.cancelAll();
}
