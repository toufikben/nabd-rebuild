import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/database_migration_service.dart';
import 'package:nabd/services/encryption_service.dart';

class _TestEncryptionService extends EncryptionService {
  _TestEncryptionService(this.key);

  final List<int> key;
  final metadata = <String, String>{};

  @override
  Future<void> initialize({bool hasExistingData = false}) async {}

  @override
  Future<List<int>> hiveKeyBytes() async => key;

  @override
  Future<String?> readMetadata(String key) async => metadata[key];

  @override
  Future<void> writeMetadata(String key, String value) async {
    metadata[key] = value;
  }
}

Future<void> _initHive(Directory directory) async {
  await Hive.close();
  Hive.init(directory.path);
}

void main() {
  final key = List<int>.generate(32, (index) => index + 1);

  test('migrates legacy plaintext and preserves every record', () async {
    final directory = await Directory.systemTemp.createTemp('nabd_migration');
    addTearDown(() async {
      await Hive.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    await _initHive(directory);

    final legacy = await Hive.openBox<dynamic>('journal_entries');
    await legacy.put('one', {'content': 'first'});
    await legacy.put('two', {'content': 'second'});
    await legacy.close();

    final encryption = _TestEncryptionService(key);
    await DatabaseMigrationService(encryption: encryption).migrate();

    final migrated = await Hive.openBox<dynamic>(
      'journal_entries',
      encryptionCipher: HiveAesCipher(key),
    );
    expect(migrated.length, 2);
    expect(migrated.get('one'), {'content': 'first'});
    expect(migrated.get('two'), {'content': 'second'});
  });

  test('recovers an interrupted migration from encrypted staging', () async {
    final directory = await Directory.systemTemp.createTemp('nabd_recovery');
    addTearDown(() async {
      await Hive.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    await _initHive(directory);

    final staging = await Hive.openBox<dynamic>(
      'journal_entries__encrypted_migration',
      encryptionCipher: HiveAesCipher(key),
    );
    await staging.put('recovered', {'content': 'safe'});
    await staging.flush();
    await staging.close();

    final encryption = _TestEncryptionService(key);
    await DatabaseMigrationService(encryption: encryption).migrate();

    final recovered = await Hive.openBox<dynamic>(
      'journal_entries',
      encryptionCipher: HiveAesCipher(key),
    );
    expect(recovered.get('recovered'), {'content': 'safe'});
  });

  test('does not accept staging encrypted with an unrelated key', () async {
    final directory = await Directory.systemTemp.createTemp('nabd_corrupt');
    addTearDown(() async {
      await Hive.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    await _initHive(directory);

    final wrongKey = List<int>.generate(32, (index) => 255 - index);
    final staging = await Hive.openBox<dynamic>(
      'journal_entries__encrypted_migration',
      encryptionCipher: HiveAesCipher(wrongKey),
    );
    await staging.put('secret', 'wrong-key');
    await staging.close();

    final encryption = _TestEncryptionService(key);
    Object? asyncFailure;
    await runZonedGuarded(
      () async {
        try {
          await DatabaseMigrationService(encryption: encryption).migrate();
        } catch (error) {
          asyncFailure = error;
        }
      },
      (error, _) {
        asyncFailure = error;
      },
    );
    expect(asyncFailure, isNotNull);
    expect(await Hive.boxExists('journal_entries'), isFalse);
  });

  group('a migrated box whose last write was cut short', () {
    late Directory directory;
    late _TestEncryptionService encryption;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nabd_torn');
      await _initHive(directory);
      encryption = _TestEncryptionService(key)
        ..metadata['nabd_hive_schema_version'] =
            '${DatabaseMigrationService.schemaVersion}'
        ..metadata['box_journal_entries'] =
            '${DatabaseMigrationService.schemaVersion}';
      final box = await Hive.openBox<dynamic>(
        'journal_entries',
        encryptionCipher: HiveAesCipher(key),
      );
      await box.put('kept', {'content': 'whole'});
      await box.put('torn', {'content': 'cut short'});
      await box.close();
      // A kill mid-write leaves the last frame incomplete.
      final file = File('${directory.path}/journal_entries.hive');
      final bytes = file.readAsBytesSync();
      file.writeAsBytesSync(bytes.sublist(0, bytes.length - 5));
    });

    tearDown(() async {
      await Hive.close();
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test('is kept, losing only the torn write', () async {
      await DatabaseMigrationService(
        encryption: encryption,
        hiveDirectory: directory,
      ).migrate();

      final box = await Hive.openBox<dynamic>(
        'journal_entries',
        encryptionCipher: HiveAesCipher(key),
      );
      expect(box.get('kept'), {'content': 'whole'});
      expect(box.containsKey('torn'), isFalse);
      expect(
        directory.listSync().where((f) => f.path.contains('probe')),
        isEmpty,
      );
    });

    test('is not truncated when the key is wrong', () async {
      final wrong = List<int>.generate(32, (index) => 200 - index);
      final length = File(
        '${directory.path}/journal_entries.hive',
      ).lengthSync();

      await expectLater(
        DatabaseMigrationService(
          encryption: _TestEncryptionService(wrong)
            ..metadata.addAll(encryption.metadata),
          hiveDirectory: directory,
        ).migrate(),
        throwsA(anything),
      );

      expect(
        File('${directory.path}/journal_entries.hive').lengthSync(),
        length,
      );
    });
  });
}
