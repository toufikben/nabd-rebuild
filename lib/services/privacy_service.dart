import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'encryption_service.dart';

/// Deletes all user-owned local data and rotates the Hive key only after all
/// encrypted boxes have been safely closed.
class PrivacyService {
  static const _boxNames = <String>[
    'journal_entries',
    'settings',
    'moods',
    'tags',
    'garden',
  ];

  final EncryptionService encryption;
  final Future<Directory> Function() _documentsDirectory;

  PrivacyService({
    EncryptionService? encryption,
    Future<Directory> Function()? documentsDirectory,
  })  : encryption = encryption ?? EncryptionService(),
        _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory;

  Future<void> deleteEverything() async {
    final oldKey = await encryption.currentKeyBytes();
    final snapshots = <String, Map<dynamic, dynamic>>{};
    for (final name in _boxNames) {
      final box = Hive.box(name);
      snapshots[name] = {
        for (final key in box.keys) key: box.get(key),
      };
    }

    try {
      await Hive.close();
      for (final name in _boxNames) {
        if (await Hive.boxExists(name)) {
          await Hive.deleteBoxFromDisk(name);
        }
      }

      await encryption.rotateKey();
      final newKey = HiveAesCipher(await encryption.currentKeyBytes());
      await _openAll(newKey);
      await _verifyOpenBoxes();

      final docs = await _documentsDirectory();
      for (final directoryName in ['images', 'audio']) {
        final directory = Directory('${docs.path}/$directoryName');
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    } catch (_) {
      await _rollback(oldKey, snapshots);
      rethrow;
    }
  }

  Future<void> _rollback(
    List<int> oldKey,
    Map<String, Map<dynamic, dynamic>> snapshots,
  ) async {
    try {
      await Hive.close();
      for (final name in _boxNames) {
        if (await Hive.boxExists(name)) {
          await Hive.deleteBoxFromDisk(name);
        }
      }
      await encryption.restoreKeyBytes(oldKey);
      final cipher = HiveAesCipher(oldKey);
      await _openAll(cipher);
      for (final entry in snapshots.entries) {
        await Hive.box(entry.key).putAll(entry.value);
      }
    } catch (_) {
      // Preserve the original failure. Startup will show the generic secure
      // storage failure screen rather than opening an unverifiable store.
      await Hive.close();
    }
  }

  Future<void> _openAll(HiveAesCipher cipher) async {
    for (final name in _boxNames) {
      await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    }
  }

  Future<void> _verifyOpenBoxes() async {
    for (final name in _boxNames) {
      final box = Hive.box(name);
      const probeKey = '__delete_all_probe__';
      await box.put(probeKey, true);
      if (box.get(probeKey) != true) {
        throw StateError('Rotated box is not readable');
      }
      await box.delete(probeKey);
      await box.flush();
    }
  }

  Future<int> getStorageUsageBytes() async {
    var total = 0;
    final docs = await _documentsDirectory();
    for (final entity in docs.listSync(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
