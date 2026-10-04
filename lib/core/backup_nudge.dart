import 'package:hive/hive.dart';

import 'storage.dart';

/// A gentle reminder to export a backup. Nabd keeps everything on the phone
/// and Android cloud backup is off on purpose, so a lost phone loses the
/// journal unless the writer exports a `.nabd` file now and then.
class BackupNudge {
  static const lastBackupKey = 'last_backup_at';
  static const snoozedUntilKey = 'backup_nudge_snoozed_until';

  /// Not worth a nudge until there is something to lose.
  static const minEntries = 5;
  static const remindAfter = Duration(days: 30);
  static const snooze = Duration(days: 7);

  static bool shouldShow({
    required int entryCount,
    required DateTime now,
    DateTime? lastBackup,
    DateTime? snoozedUntil,
  }) {
    if (entryCount < minEntries) return false;
    if (snoozedUntil != null && now.isBefore(snoozedUntil)) return false;
    return lastBackup == null || now.difference(lastBackup) >= remindAfter;
  }

  static Box get _settings => Hive.box(HiveBoxes.settings);

  static DateTime? _read(String key) {
    final raw = _settings.get(key);
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  static DateTime? get lastBackup => _read(lastBackupKey);

  static bool shouldShowNow(int entryCount, [DateTime? now]) => shouldShow(
        entryCount: entryCount,
        now: now ?? DateTime.now(),
        lastBackup: lastBackup,
        snoozedUntil: _read(snoozedUntilKey),
      );

  static Future<void> recordBackup([DateTime? at]) => _settings.put(
      lastBackupKey, (at ?? DateTime.now()).toIso8601String());

  static Future<void> snoozeNow([DateTime? now]) => _settings.put(
      snoozedUntilKey, (now ?? DateTime.now()).add(snooze).toIso8601String());
}
