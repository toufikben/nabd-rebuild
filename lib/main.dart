import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'services/encryption_service.dart';
import 'services/notification_service.dart';
import 'services/database_migration_service.dart';
import 'services/settings_service.dart';
import 'services/backup_scheduler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? storageError;
  try {
    await Hive.initFlutter();
    await DatabaseMigrationService().migrate();
    final hiveCipher = HiveAesCipher(
      await EncryptionService().hiveKeyBytes(),
    );
    await Hive.openBox('journal_entries', encryptionCipher: hiveCipher);
    await Hive.openBox('settings', encryptionCipher: hiveCipher);
    await Hive.openBox('moods', encryptionCipher: hiveCipher);
    await Hive.openBox('tags', encryptionCipher: hiveCipher);
    await Hive.openBox('garden', encryptionCipher: hiveCipher);
  } catch (_) {
    storageError = const Object();
  }

  if (storageError != null) {
    runApp(const StorageFailureApp());
    return;
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  try {
    await BackupSchedulerService.initialize();
  } catch (_) {
    // The app remains usable; automatic backup can be enabled after retrying.
  }

  runApp(const ProviderScope(child: NabdApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeDeferredServices());
  });
}

Future<void> _initializeDeferredServices() async {
  await NotificationService.init();
  await SettingsService.init();
  await EncryptionService().initialize();
  await MobileAds.instance.initialize();
}

class StorageFailureApp extends StatelessWidget {
  const StorageFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56),
                const SizedBox(height: 20),
                const Text(
                  'Secure storage could not be opened.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your data was not changed. Please restart the app or contact support.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
