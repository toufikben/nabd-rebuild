import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'backup_service.dart';
import 'encryption_service.dart';

const automaticBackupTask = 'nabd.automatic_database_backup';
const automaticBackupUniqueName = 'nabd-automatic-database-backup';
const automaticBackupPasswordKey = 'nabd_automatic_backup_password';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != automaticBackupTask) return true;

    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    try {
      await Hive.initFlutter();
      final cipher = HiveAesCipher(await EncryptionService().hiveKeyBytes());
      await Hive.openBox('journal_entries', encryptionCipher: cipher);
      await Hive.openBox('settings', encryptionCipher: cipher);
      await Hive.openBox('moods', encryptionCipher: cipher);
      await Hive.openBox('tags', encryptionCipher: cipher);
      await Hive.openBox('garden', encryptionCipher: cipher);

      final settings = Hive.box('settings');
      final enabled = settings.get('automatic_backup_enabled', defaultValue: false) as bool;
      final directory = settings.get('automatic_backup_directory') as String?;
      final password = await _secureStorage.read(key: automaticBackupPasswordKey);
      if (!enabled || directory == null || directory.isEmpty || password == null || password.isEmpty) {
        return false;
      }

      final backup = await BackupService().createBackupAtDirectory(
        password: password,
        directoryPath: directory,
      );
      await settings.put('automatic_backup_last_success', DateTime.now().toIso8601String());
      await settings.put('automatic_backup_last_file', backup.path);
      return true;
    } catch (_) {
      return false;
    } finally {
      await Hive.close();
    }
  });
}

class BackupSchedulerService {
  static final Workmanager _workmanager = Workmanager();

  static Future<void> initialize() async {
    await _workmanager.initialize(backupCallbackDispatcher);
  }

  static Future<void> schedule({required Duration frequency}) async {
    await _workmanager.cancelByUniqueName(automaticBackupUniqueName);
    await _workmanager.registerPeriodicTask(
      automaticBackupUniqueName,
      automaticBackupTask,
      frequency: frequency,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: true,
      ),
    );
  }

  static Future<void> cancel() async {
    await _workmanager.cancelByUniqueName(automaticBackupUniqueName);
  }
}
