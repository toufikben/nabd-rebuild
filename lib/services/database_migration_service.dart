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
    final dataState = await _detectDataState();
    await encryption.initialize(
      hasExistingData: dataState == HiveDataState.encryptedOrUnreadable,
    );
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

  Future<HiveDataState> _detectDataState() async {
    var foundLegacyData = false;
    for (final name in _boxes) {
      if (!await Hive.boxExists(name)) continue;
      try {
        final box = await Hive.openBox<dynamic>(name);
        foundLegacyData = true;
        await box.close();
      } catch (_) {
        return HiveDataState.encryptedOrUnreadable;
      }
    }
    return foundLegacyData
        ? HiveDataState.legacyPlaintext
        : HiveDataState.empty;
  }

  Future<void> _migrateBox(String name, List<int> key) async {
    final temporaryName = '$name$_temporarySuffix';
    late final Box<dynamic> oldBox;
    try {
      oldBox = await Hive.openBox<dynamic>(name);
    } catch (_) {
      // A previous run may have completed the encrypted copy but stopped
      // before writing its metadata marker. Verify it and leave it intact.
      final encrypted = await Hive.openBox<dynamic>(
        name,
        encryptionCipher: HiveAesCipher(key),
      );
      for (final entryKey in encrypted.keys) {
        encrypted.get(entryKey);
      }
      await encrypted.close();
      return;
    }
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
    // Read the target before deleting the recovery copy. If this throws,
    // the encrypted staging box remains available for the next startup.
    for (final key in encryptedBox.keys) {
      encryptedBox.get(key);
    }
    await staged.close();
    await Hive.deleteBoxFromDisk(temporaryName);
    await encryptedBox.close();
  }
}

enum HiveDataState { empty, legacyPlaintext, encryptedOrUnreadable }
