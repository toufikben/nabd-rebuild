import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'encryption_service.dart';

/// Migrates legacy plaintext Hive boxes to encrypted boxes without changing
/// their public names. The source is retained until an encrypted target has
/// been fully written and read back for validation.
class DatabaseMigrationService {
  static const schemaVersion = 1;
  static const _marker = 'nabd_hive_schema_version';
  static const _temporarySuffix = '__encrypted_migration';
  static const _targetSuffix = '__encrypted_target';
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
    var foundLegacy = false;
    for (final name in _boxes) {
      final hasPublicBox = await Hive.boxExists(name);
      final hasRecoveryBox = await Hive.boxExists('$name$_temporarySuffix') ||
          await Hive.boxExists('$name$_targetSuffix');
      if (!hasPublicBox && hasRecoveryBox) {
        return HiveDataState.encryptedOrUnreadable;
      }
      if (!hasPublicBox) continue;
      try {
        final box = await Hive.openBox<dynamic>(name, crashRecovery: false);
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
        final plain = await Hive.openBox<dynamic>(name, crashRecovery: false);
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

    final staging = await Hive.openBox<dynamic>(
      stagingName,
      encryptionCipher: HiveAesCipher(key),
      crashRecovery: false,
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

    final target = await Hive.openBox<dynamic>(
      targetName,
      encryptionCipher: HiveAesCipher(key),
      crashRecovery: false,
    );
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

    final finalBox = await Hive.openBox<dynamic>(
      name,
      encryptionCipher: HiveAesCipher(key),
      crashRecovery: false,
    );
    final targetForCommit = await Hive.openBox<dynamic>(
      targetName,
      encryptionCipher: HiveAesCipher(key),
      crashRecovery: false,
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
      final box = await Hive.openBox<dynamic>(
        name,
        encryptionCipher: HiveAesCipher(key),
        crashRecovery: false,
      );
      for (final entryKey in box.keys) {
        box.get(entryKey);
      }
      await box.close();
      return true;
    } catch (_) {
      return false;
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
          !_valuesEqual(box.get(entry.key), entry.value)) {
        throw StateError('Migration key/value mismatch');
      }
    }
  }

  bool _valuesEqual(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      for (final key in left.keys) {
        if (!right.containsKey(key) || !_valuesEqual(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      return left.length == right.length &&
          List.generate(left.length, (i) => _valuesEqual(left[i], right[i]))
              .every((value) => value);
    }
    if (left is DateTime && right is DateTime) return left == right;
    if (left is num && right is num) return left == right;
    if (left == null || right == null) return left == right;
    try {
      return jsonEncode(left) == jsonEncode(right);
    } catch (_) {
      return left == right;
    }
  }
}

enum HiveDataState { empty, legacyPlaintext, encryptedOrUnreadable }
