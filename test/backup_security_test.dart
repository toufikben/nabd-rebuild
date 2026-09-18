import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/backup_service.dart';

void main() {
  test('accepts only known backup paths', () {
    expect(BackupService.isSafeArchivePath('entries.json'), isTrue);
    expect(BackupService.isSafeArchivePath('images/photo.jpg'), isTrue);
    expect(BackupService.isSafeArchivePath('audio/voice.m4a'), isTrue);
  });

  test('rejects traversal, absolute and encoded traversal paths', () {
    expect(BackupService.isSafeArchivePath('../entries.json'), isFalse);
    expect(BackupService.isSafeArchivePath(r'..\entries.json'), isFalse);
    expect(BackupService.isSafeArchivePath('/tmp/entries.json'), isFalse);
    expect(BackupService.isSafeArchivePath('%2e%2e/entries.json'), isFalse);
    expect(BackupService.isSafeArchivePath('images/../settings.json'), isFalse);
  });

  test('does not treat entitlement files as a supported archive path', () {
    expect(BackupService.isSafeArchivePath('is_pro.json'), isFalse);
  });

  test('restore settings cannot grant purchase entitlement', () {
    final restored = BackupService.filterRestoredSettings({
      'is_pro': true,
      'is_lifetime': true,
      'pro_expiry': '2099-01-01T00:00:00.000Z',
      'theme_mode': 'dark',
    });
    expect(restored.containsKey('is_pro'), isFalse);
    expect(restored.containsKey('is_lifetime'), isFalse);
    expect(restored.containsKey('pro_expiry'), isFalse);
    expect(restored['theme_mode'], 'dark');
  });

  test('restore rejects malformed and duplicate entry payloads', () {
    expect(
        BackupService.validateEntriesPayload([
          {'id': 'one', 'title': 'A', 'content': 'B'},
        ]),
        isTrue);
    expect(
        BackupService.validateEntriesPayload([
          {'id': 'one'},
          {'id': 'one'},
        ]),
        isFalse);
    expect(
        BackupService.validateEntriesPayload([
          {'id': 'one', 'content': 42},
        ]),
        isFalse);
  });
}
