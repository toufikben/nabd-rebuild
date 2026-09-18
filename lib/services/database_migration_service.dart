import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'encryption_service.dart';

/// Migrates legacy plaintext Hive boxes to encrypted boxes without changing
/// their public names, so existing callers continue to use the same API.
class DatabaseMigrationService {
  static const schemaVersion = 1;
  static const _marker = 'nabd_hive_schema_version';
  static const _temporarySuffix = '__encrypted_migration';
  static const _boxes = <String>[
    'journal_entries',
    'settings',
    'moods',
    'tags',
    'garden',
  ];

  final EncryptionService encryption;

  DatabaseMigrationService({EncryptionService? encryption})
      : encryption = encryption ?? EncryptionService();

  Future<void> migrate() async {
    await encryption.initialize();
    final currentVersion = await encryption.readMetadata(_marker);
    if (currentVersion == '$schemaVersion') return;

    final key = await encryption.hiveKeyBytes();
    for (final name in _boxes) {
      if (await encryption.readMetadata('box_$name') == '$schemaVersion') {
        continue;
      }
      await _migrateBox(name, key);
      await encryption.writeMetadata('box_$name', '$schemaVersion');
    }
    await encryption.writeMetadata(_marker, '$schemaVersion');
  }

  Future<void> _migrateBox(String name, List<int> key) async {
    final temporaryName = '$name$_temporarySuffix';
    final oldBox = await Hive.openBox<dynamic>(name);
    final snapshot = <dynamic, dynamic>{
      for (final key in oldBox.keys) key: oldBox.get(key),
    };
    await oldBox.close();

    // A completed temporary box is valid recovery material after an
    // interrupted migration. Reuse it rather than discarding user data.
    final encryptedTemporary = await Hive.openBox<dynamic>(
      temporaryName,
      encryptionCipher: HiveAesCipher(key),
    );
    if (encryptedTemporary.isEmpty && snapshot.isNotEmpty) {
      await encryptedTemporary.putAll(snapshot);
      await encryptedTemporary.flush();
    }
    await encryptedTemporary.close();

    // Delete the plaintext box only after the encrypted copy is durable.
    await Hive.deleteBoxFromDisk(name);

    final encryptedBox = await Hive.openBox<dynamic>(
      name,
      encryptionCipher: HiveAesCipher(key),
    );
    final staged = await Hive.openBox<dynamic>(
      temporaryName,
      encryptionCipher: HiveAesCipher(key),
    );
    if (encryptedBox.isEmpty && staged.isNotEmpty) {
      await encryptedBox.putAll({
        for (final key in staged.keys) key: staged.get(key),
      });
      await encryptedBox.flush();
    }
    await staged.close();
    await Hive.deleteBoxFromDisk(temporaryName);
    await encryptedBox.close();
  }
}
