import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Deletes all user-owned local data while preserving the active encryption
/// key. Key rotation is intentionally deferred because rotating an open Hive
/// store here could make unrelated application state unreadable.
class PrivacyService {
  Future<void> deleteEverything() async {
    for (final boxName in [
      'journal_entries',
      'settings',
      'moods',
      'tags',
      'garden'
    ]) {
      final box = Hive.box(boxName);
      await box.clear();
    }

    final docs = await getApplicationDocumentsDirectory();
    for (final directoryName in ['images', 'audio']) {
      final directory = Directory('${docs.path}/$directoryName');
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }

  Future<int> getStorageUsageBytes() async {
    var total = 0;
    final docs = await getApplicationDocumentsDirectory();
    for (final entity in docs.listSync(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
