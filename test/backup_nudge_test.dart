import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/backup_nudge.dart';
import 'package:nabd/services/backup_service.dart';

void main() {
  final now = DateTime(2026, 10, 4, 12);

  test('waits until there is something to lose', () {
    expect(BackupNudge.shouldShow(entryCount: 4, now: now), isFalse);
    expect(BackupNudge.shouldShow(entryCount: 5, now: now), isTrue);
  });

  test('a recent backup silences it for 30 days', () {
    bool show(int daysAgo) => BackupNudge.shouldShow(
          entryCount: 20,
          now: now,
          lastBackup: now.subtract(Duration(days: daysAgo)),
        );
    expect(show(3), isFalse);
    expect(show(29), isFalse);
    expect(show(30), isTrue);
  });

  test('"later" hides it for a week', () {
    expect(
      BackupNudge.shouldShow(
        entryCount: 20,
        now: now,
        snoozedUntil: now.add(const Duration(days: 2)),
      ),
      isFalse,
    );
    expect(
      BackupNudge.shouldShow(
        entryCount: 20,
        now: now,
        snoozedUntil: now.subtract(const Duration(minutes: 1)),
      ),
      isTrue,
    );
  });

  test('backup dates stay on this phone and never travel in a backup', () {
    expect(BackupService.isDeviceKey(BackupNudge.lastBackupKey), isTrue);
    expect(BackupService.isDeviceKey(BackupNudge.snoozedUntilKey), isTrue);
  });
}
