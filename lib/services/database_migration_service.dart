import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'encryption_service.dart';
import 'hive_strict_open.dart';
import 'hive_value_equality.dart';
import '../core/storage.dart';

/// Migrates legacy plaintext Hive boxes to encrypted boxes without changing
/// their public names. The source is retained until an encrypted target has
/// been fully written and read back for validation.
class DatabaseMigrationService {
  static const schemaVersion = 1;
  static const _marker = 'nabd_hive_schema_version';
  static const _temporarySuffix = '__encrypted_migration';
  static const _targetSuffix = '__encrypted_target';
  static const _probeSuffix = '__torn_probe';
  static const _boxes = HiveBoxes.all;

  final EncryptionService encryption;

  /// Where Hive keeps its box files. With it, a box whose last write was cut
  /// short by the process dying is recognised as readable rather than
  /// corrupt; without it such a box fails validation.
  final Directory? hiveDirectory;

  DatabaseMigrationService({EncryptionService? encryption, this.hiveDirectory})
    : encryption = encryption ?? EncryptionService();

  Future<void> migrate() async {
    final dataState = await _detectDataState();
    await encryption.initialize(
      hasExistingData: dataState == HiveDataState.encryptedOrUnreadable,
    );
    final key = await encryption.hiveKeyBytes();

    for (final name in _boxes) {
      if (await encryption.readMetadata('box_$name') == '$schemaVersion' &&
          await _encryptedBoxIsValid(name, key)) {
        continue;
      }
      await _migrateBox(name, key);
      await encryption.writeMetadata('box_$name', '$schemaVersion');
    }
    await encryption.writeMetadata(_marker, '$schemaVersion');
  }

  Future<HiveDataState> _detectDataState() async {
    // Once migrated, the boxes are encrypted. Probing them as plaintext
    // would only fail, and Hive reports each failed open as an unhandled
    // error even though it is caught here.
    if (await encryption.readMetadata(_marker) == '$schemaVersion') {
      for (final name in _boxes) {
        if (await Hive.boxExists(name)) {
          return HiveDataState.encryptedOrUnreadable;
        }
      }
      return HiveDataState.empty;
    }
    var foundLegacy = false;
    for (final name in _boxes) {
      final hasPublicBox = await Hive.boxExists(name);
      final hasRecoveryBox =
          await Hive.boxExists('$name$_temporarySuffix') ||
          await Hive.boxExists('$name$_targetSuffix');
      if (!hasPublicBox && hasRecoveryBox) {
        return HiveDataState.encryptedOrUnreadable;
      }
      if (!hasPublicBox) continue;
      try {
        final box = await openBoxStrict(name);
        foundLegacy = true;
        await box.close();
      } catch (_) {
        return HiveDataState.encryptedOrUnreadable;
      }
    }
    return foundLegacy ? HiveDataState.legacyPlaintext : HiveDataState.empty;
  }

  Future<void> _migrateBox(String name, List<int> key) async {
    final stagingName = '$name$_temporarySuffix';
    final targetName = '$name$_targetSuffix';
    Map<dynamic, dynamic>? source;
    final publicBoxExists = await Hive.boxExists(name);
    final recoveryStagingExists = await Hive.boxExists(stagingName);
    late final bool existingEncrypted;

    if (publicBoxExists) {
      try {
        final plain = await openBoxStrict(name);
        source = _snapshot(plain);
        await plain.close();
      } catch (_) {
        // The public name may already be encrypted, or the process may have
        // stopped after deleting the plaintext source. Recovery below uses
        // validated staging/target copies instead of creating fake data.
      }
    }

    existingEncrypted = source == null && publicBoxExists
        ? await _encryptedBoxIsValid(name, key)
        : false;

    if (source == null && existingEncrypted) {
      return;
    }

    final staging = await openBoxStrict(
      stagingName,
      cipher: HiveAesCipher(key),
    );
    if (source == null && recoveryStagingExists && staging.isEmpty) {
      await staging.close();
      throw StateError('Migration staging is empty or corrupted for $name');
    }
    if (source != null) {
      await staging.clear();
      await staging.putAll(source);
      await staging.flush();
      await _validateBox(staging, source);
      await encryption.writeMetadata('box_state_$name', 'staged');
    } else if (staging.isNotEmpty) {
      await _validateBox(staging, _snapshot(staging));
    }
    final stagedData = _snapshot(staging);
    if (source == null &&
        publicBoxExists &&
        stagedData.isEmpty &&
        !existingEncrypted &&
        !await _encryptedBoxIsValid(name, key)) {
      await staging.close();
      throw StateError('No recoverable migration data for $name');
    }

    final target = await openBoxStrict(targetName, cipher: HiveAesCipher(key));
    if (source != null) {
      await target.clear();
    }
    if (target.isEmpty && stagedData.isNotEmpty) {
      await target.putAll(stagedData);
      await target.flush();
    }
    final targetData = _snapshot(target);
    if (stagedData.isNotEmpty) {
      await _validateBox(target, stagedData);
    } else if (targetData.isNotEmpty) {
      await _validateBox(target, targetData);
    }
    await target.close();
    await staging.close();

    // The encrypted target and staging copy are now independently readable.
    // Only now may the legacy source be removed.
    if (await Hive.boxExists(name)) {
      try {
        final open = Hive.isBoxOpen(name) ? Hive.box(name) : null;
        if (open != null) await open.close();
      } catch (_) {}
      await Hive.deleteBoxFromDisk(name);
    }

    final finalBox = await openBoxStrict(name, cipher: HiveAesCipher(key));
    final targetForCommit = await openBoxStrict(
      targetName,
      cipher: HiveAesCipher(key),
    );
    final commitData = _snapshot(targetForCommit);
    await _validateBox(targetForCommit, commitData);
    await finalBox.clear();
    await finalBox.putAll(commitData);
    await finalBox.flush();
    await _validateBox(finalBox, commitData);
    await targetForCommit.close();
    await finalBox.close();

    await Hive.deleteBoxFromDisk(targetName);
    await Hive.deleteBoxFromDisk(stagingName);
    await encryption.writeMetadata('box_state_$name', 'completed');
  }

  Future<bool> _encryptedBoxIsValid(String name, List<int> key) async {
    if (!await Hive.boxExists(name)) return false;
    try {
      final box = await openBoxStrict(name, cipher: HiveAesCipher(key));
      for (final entryKey in box.keys) {
        box.get(entryKey);
      }
      await box.close();
      return true;
    } on HiveError {
      return _onlyTheTailIsTorn(name, key);
    } catch (_) {
      return false;
    }
  }

  /// A box fails its checksum both when the key is wrong and when the last
  /// write was cut short. Hive's own recovery truncates at the first bad
  /// frame, which with a wrong key would be the very first one: everything.
  /// So recovery runs on a copy, and the box only counts as readable when
  /// the copy keeps at least its first frame, which proves the key. Startup
  /// then opens the real box with recovery on and loses only the torn write.
  Future<bool> _onlyTheTailIsTorn(String name, List<int> key) async {
    final directory = hiveDirectory;
    if (directory == null) return false;
    final source = File('${directory.path}/${name.toLowerCase()}.hive');
    if (!source.existsSync() || source.lengthSync() == 0) return false;
    final probeName = '$name$_probeSuffix';
    final probe = File('${directory.path}/${probeName.toLowerCase()}.hive');
    try {
      await source.copy(probe.path);
      final box = await Hive.openBox<dynamic>(
        probeName,
        encryptionCipher: HiveAesCipher(key),
      );
      await box.close();
      return probe.lengthSync() > 0;
    } catch (_) {
      return false;
    } finally {
      try {
        await Hive.deleteBoxFromDisk(probeName);
      } catch (_) {}
    }
  }

  Map<dynamic, dynamic> _snapshot(Box<dynamic> box) => {
    for (final key in box.keys) key: box.get(key),
  };

  Future<void> _validateBox(
    Box<dynamic> box,
    Map<dynamic, dynamic> expected,
  ) async {
    if (box.length != expected.length) {
      throw StateError('Migration item count mismatch');
    }
    for (final entry in expected.entries) {
      if (!box.containsKey(entry.key) ||
          !hiveValuesEqual(box.get(entry.key), entry.value)) {
        throw StateError('Migration key/value mismatch');
      }
    }
  }
}

enum HiveDataState { empty, legacyPlaintext, encryptedOrUnreadable }
