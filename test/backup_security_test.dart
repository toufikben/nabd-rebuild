import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/backup_service.dart';

void main() {
  test('backup creation requires a password', () async {
    expect(
      () => BackupService().createBackup(password: ''),
      throwsA(isA<FormatException>()),
    );
  });

  test('restore rejects missing password without reading a backup', () async {
    final result = await BackupService().restoreBackup('/does/not/exist');
    expect(result.ok, isFalse);
    expect(result.error, 'Backup password is required');
  });

  test('restore rejects corrupted and unsupported encrypted envelopes',
      () async {
    final directory = await Directory.systemTemp.createTemp('nabd_backup_test');
    addTearDown(() => directory.delete(recursive: true));

    final corrupted = File('${directory.path}/corrupted.nabd')
      ..writeAsBytesSync([1, 2, 3, 4]);
    final corruptedResult = await BackupService().restoreBackup(
      corrupted.path,
      password: 'correct-password',
    );
    expect(corruptedResult.ok, isFalse);

    final unsupported = File('${directory.path}/unsupported.nabd')
      ..writeAsBytesSync([
        0x4E,
        0x41,
        0x42,
        0x44,
        99,
        ...List<int>.filled(40, 0),
      ]);
    final unsupportedResult = await BackupService().restoreBackup(
      unsupported.path,
      password: 'correct-password',
    );
    expect(unsupportedResult.ok, isFalse);
  });

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

  test('filters entitlement keys before backup payload creation', () {
    expect(BackupService.isEntitlementKey('is_pro'), isTrue);
    expect(BackupService.isEntitlementKey('IS_LIFETIME'), isTrue);
    expect(BackupService.isEntitlementKey('theme_mode'), isFalse);
    expect(
      BackupService.filterRestoredSettings({
        'theme_mode': 'dark',
        'is_pro': true,
        'is_lifetime': true,
        'pro_expiry': '2099-01-01T00:00:00Z',
      }),
      {'theme_mode': 'dark'},
    );
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
