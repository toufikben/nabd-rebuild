import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/core/storage.dart';
import 'package:nabd/services/backup_service.dart';
import 'package:nabd/services/database_service.dart';
import 'package:nabd/services/encryption_service.dart';
import 'package:nabd/services/media_vault.dart';

class _MemoryKeystore extends EncryptionService {
  final Map<String, String> secrets = {};

  @override
  Future<String?> readSecret(String key) async => secrets[key];

  @override
  Future<void> writeSecret(String key, String value) async =>
      secrets[key] = value;

  @override
  Future<void> deleteSecret(String key) async => secrets.remove(key);
}

Map<String, dynamic> _entry(String id, String content,
        {List<String> images = const [], String updatedAt = '2026-10-01T10:00:00.000'}) =>
    {
      'id': id,
      'title': id.toUpperCase(),
      'content': content,
      'createdAt': '2026-10-01T10:00:00.000',
      'updatedAt': updatedAt,
      'imagePaths': images,
    };

void main() {
  late Directory root;
  late Directory docs;
  late Directory temp;
  late MediaVault vault;
  late BackupService service;

  setUp(() async {
    EncryptionService.resetCachedKey();
    root = await Directory.systemTemp.createTemp('nabd_backup');
    docs = Directory('${root.path}/docs')..createSync(recursive: true);
    temp = Directory('${root.path}/temp')..createSync(recursive: true);
    Hive.init('${root.path}/hive');
    for (final name in HiveBoxes.all) {
      await Hive.openBox<dynamic>(name);
    }
    final keystore = _MemoryKeystore();
    vault = MediaVault(
      encryption: keystore,
      documentsDirectory: () async => docs,
      temporaryDirectory: () async => temp,
    );
    service = BackupService(
      encryption: keystore,
      media: vault,
      documentsDirectory: () async => docs,
      temporaryDirectory: () async => temp,
    );
  });

  tearDown(() async {
    await Hive.close();
    DatabaseService.invalidate();
    EncryptionService.resetCachedKey();
    await root.delete(recursive: true);
  });

  Box journal() => Hive.box(HiveBoxes.journal);
  Box content() => Hive.box(HiveBoxes.content);
  Box settings() => Hive.box(HiveBoxes.settings);

  test('a backup restores entries, content and encrypted photos', () async {
    final photo = await vault.store(Uint8List.fromList([1, 2, 3]),
        folder: 'images', extension: '.jpg');
    await journal().put('a', _entry('a', 'saved', images: [photo]));
    await content().put('unsent_letters', [
      {'id': 'l1', 'content': 'dear me'},
    ]);
    await settings().putAll({'themeMode': 'dark', 'lock_enabled': true});

    final backup = await service.createBackup(password: 'correct-password');
    expect(backup.path, endsWith('.nabd'));

    await journal().clear();
    await content().clear();
    await vault.delete(photo);

    final wrong = await service.restoreBackup(backup.path,
        password: 'wrong-password', mode: RestoreMode.replace);
    expect(wrong.ok, isFalse);
    expect(wrong.failure, BackupError.wrongPasswordOrCorrupt);

    final result = await service.restoreBackup(backup.path,
        password: 'correct-password', mode: RestoreMode.replace);
    expect(result.ok, isTrue);
    expect(result.imagesRestored, 1);
    final restored = journal().get('a') as Map;
    final newPhoto = (restored['imagePaths'] as List).single as String;
    expect(MediaVault.isEncrypted(newPhoto), isTrue);
    expect(await vault.read(newPhoto), [1, 2, 3]);
    expect(content().get('unsent_letters')[0]['content'], 'dear me');
    expect(settings().get('themeMode'), 'dark');
  });

  test('the lock and other device settings never travel', () async {
    await settings().putAll({
      'lock_enabled': true,
      'is_pro': true,
      'onboarding_completed': true,
      'language': 'ar',
    });
    final backup = await service.createBackup(password: 'pw-123456');
    await settings().clear();

    await service.restoreBackup(backup.path,
        password: 'pw-123456', mode: RestoreMode.replace);

    expect(settings().get('language'), 'ar');
    expect(settings().containsKey('lock_enabled'), isFalse);
    expect(settings().containsKey('is_pro'), isFalse);
    expect(settings().containsKey('onboarding_completed'), isFalse);
  });

  test('merge keeps what was written since the backup', () async {
    await journal().put('a', _entry('a', 'old'));
    await content().put('worry_box', [
      {'id': 'w1', 'text': 'from the backup'},
    ]);
    await settings().put('language', 'ar');
    final backup = await service.createBackup(password: 'pw-123456');

    await journal().put('a', _entry('a', 'edited later',
        updatedAt: '2026-10-02T10:00:00.000'));
    await journal().put('b', _entry('b', 'new since backup'));
    await content().put('worry_box', [
      {'id': 'w2', 'text': 'new since backup'},
    ]);
    await settings().put('language', 'en');

    final result = await service.restoreBackup(backup.path,
        password: 'pw-123456', mode: RestoreMode.merge);

    expect(result.ok, isTrue);
    expect(journal().get('a')['content'], 'edited later');
    expect(journal().containsKey('b'), isTrue);
    final worries = (content().get('worry_box') as List)
        .map((item) => (item as Map)['id'])
        .toSet();
    expect(worries, {'w1', 'w2'});
    expect(settings().get('language'), 'en');
  });

  test('replace drops media the restored journal does not use', () async {
    final keep = await vault.store(Uint8List.fromList([7]), folder: 'images');
    await journal().put('a', _entry('a', 'x', images: [keep]));
    final backup = await service.createBackup(password: 'pw-123456');

    final stray = await vault.store(Uint8List.fromList([8]), folder: 'images');
    await journal().put('z', _entry('z', 'later', images: [stray]));

    await service.restoreBackup(backup.path,
        password: 'pw-123456', mode: RestoreMode.replace);

    expect(journal().containsKey('z'), isFalse);
    expect(File('${docs.path}/$stray').existsSync(), isFalse);
  });

  test('a truncated or tampered backup changes nothing', () async {
    await journal().put('current', _entry('current', 'keep me'));
    final backup = await service.createBackup(password: 'password');
    final bytes = await backup.readAsBytes();

    final truncated = File('${temp.path}/truncated.nabd')
      ..writeAsBytesSync(bytes.sublist(0, bytes.length - 40));
    final tampered = File('${temp.path}/tampered.nabd')
      ..writeAsBytesSync(Uint8List.fromList(bytes)..[bytes.length - 1] ^= 1);

    for (final file in [truncated, tampered]) {
      final result = await service.restoreBackup(file.path,
          password: 'password', mode: RestoreMode.replace);
      expect(result.ok, isFalse);
      expect(journal().get('current')['content'], 'keep me');
    }
  });

  test('a format 1 backup from the previous version still restores',
      () async {
    final archive = Archive();
    void add(String name, Object data) {
      final bytes = utf8.encode(jsonEncode(data));
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add('entries.json', [
      _entry('old', 'from v1', images: ['/data/app/images/pic.jpg']),
    ]);
    add('settings.json', {
      'language': 'ar',
      'unsent_letters': [
        {'id': 'u1', 'content': 'hi'},
      ],
    });
    add('garden.json', {});
    add('moods.json', {});
    add('tags.json', {});
    add('achievements.json', {
      'unlocked': ['first_entry'],
    });
    archive.addFile(ArchiveFile('images/pic.jpg', 2, [5, 6]));
    add('metadata.json', {
      'version': 3,
      'formatVersion': 1,
      'app': 'nabd',
      'encrypted': true,
      'entryCount': 1,
    });
    final zip = ZipEncoder().encode(archive)!;

    final salt = Uint8List.fromList(List.filled(16, 3));
    final key = await EncryptionService()
        .deriveKeyFromPassword(password: 'legacy-pw', salt: salt);
    final aes = AesGcm.with256bits();
    final box = await aes.encrypt(zip, secretKey: key, nonce: aes.newNonce());
    final file = File('${temp.path}/old.nabd')
      ..writeAsBytesSync([
        0x4E, 0x41, 0x42, 0x44, 1,
        ...salt,
        ...box.nonce,
        ...box.cipherText,
        ...box.mac.bytes,
      ]);

    final result = await service.restoreBackup(file.path,
        password: 'legacy-pw', mode: RestoreMode.replace);

    expect(result.ok, isTrue, reason: '${result.failure}');
    final entry = journal().get('old') as Map;
    final photo = (entry['imagePaths'] as List).single as String;
    expect(await vault.read(photo), [5, 6]);
    expect(content().get('unsent_letters')[0]['content'], 'hi');
    expect(content().get('unlocked_achievements'), ['first_entry']);
    expect(settings().containsKey('unsent_letters'), isFalse);
  });

  test('merge rules for content values', () {
    expect(
      BackupService.mergeContentValue(['a'], ['a', 'b']),
      ['a', 'b'],
    );
    expect(BackupService.mergeContentValue(['a'], ['a']), isNull);
    expect(BackupService.mergeContentValue(3, 5), 5);
    expect(BackupService.mergeContentValue(5, 3), isNull);
    expect(BackupService.mergeContentValue({'x': 1}, {'x': 2}), isNull);
  });
}
