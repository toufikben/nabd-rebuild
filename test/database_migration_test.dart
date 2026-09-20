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
      await directory.delete(recursive: true);
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
      await directory.delete(recursive: true);
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
      await directory.delete(recursive: true);
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
    await runZonedGuarded(() async {
      try {
        await DatabaseMigrationService(encryption: encryption).migrate();
      } catch (error) {
        asyncFailure = error;
      }
    }, (error, _) {
      asyncFailure = error;
    });
    expect(asyncFailure, isNotNull);
    expect(await Hive.boxExists('journal_entries'), isFalse);
  });
}
