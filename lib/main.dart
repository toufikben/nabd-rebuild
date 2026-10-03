import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/storage.dart';
import 'services/database_service.dart';
import 'services/encryption_service.dart';
import 'services/notification_service.dart';
import 'services/database_migration_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Arabic month and weekday names are loaded lazily by intl; without this the
  // calendar and entry dates silently fall back to English.
  await initializeDateFormatting('ar');
  Object? storageError;
  try {
    await Hive.initFlutter();
    // Hive.initFlutter keeps its boxes in the documents directory. A key
    // rotation cut short by the process dying is finished or undone here,
    // before any box is opened.
    await EncryptionService().recoverInterruptedRotation(
      await getApplicationDocumentsDirectory(),
    );
    await DatabaseMigrationService().migrate();
    final hiveCipher = HiveAesCipher(
      await EncryptionService().hiveKeyBytes(),
    );
    for (final name in HiveBoxes.all) {
      await Hive.openBox(name, encryptionCipher: hiveCipher);
    }
    await ContentBoxMigration.run(
      settings: Hive.box(HiveBoxes.settings),
      content: Hive.box(HiveBoxes.content),
    );
    await ContentBoxMigration.foldTimeCapsules(Hive.box(HiveBoxes.content));
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

  runApp(const ProviderScope(child: NabdApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeDeferredServices());
  });
}

Future<void> _initializeDeferredServices() async {
  // Older photos and voice notes are plain files with absolute paths; move
  // them into the encrypted vault in the background.
  unawaited(DatabaseService().encryptLegacyMedia().catchError((Object error) {
    debugPrint('Legacy media encryption failed: $error');
    return 0;
  }));
  await NotificationService.init();
  await NotificationService.restoreScheduledReminder();
  await SettingsService.init();
  await EncryptionService().initialize();
  await MobileAds.instance.initialize();
}

/// Shown when the encrypted store cannot be opened, typically because the
/// keystore key is gone (a factory reset of credentials, or data copied from
/// another phone). Nothing here can decrypt the old data, so besides waiting
/// the only way forward is to start over and restore a `.nabd` export.
class StorageFailureApp extends StatefulWidget {
  const StorageFailureApp({super.key});

  @override
  State<StorageFailureApp> createState() => _StorageFailureAppState();
}

class _StorageFailureAppState extends State<StorageFailureApp> {
  bool _resetting = false;

  // Localizations are not loaded on this screen, so the text picks its
  // language directly from the device.
  bool get _arabic =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar';

  String _pick(String english, String arabic) => _arabic ? arabic : english;

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_pick('Start over?', 'البدء من جديد؟')),
        content: Text(_pick(
          'The unreadable journal on this phone will be erased and a new '
              'empty one created. You can then restore an encrypted .nabd '
              'backup from Settings. This cannot be undone.',
          'ستُمسح المذكرة غير القابلة للقراءة على هذا الهاتف ويُنشأ دفتر جديد '
              'فارغ، ويمكنك بعدها استعادة نسخة .nabd المشفرة من الإعدادات. '
              'لا يمكن التراجع عن هذا.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_pick('Cancel', 'إلغاء')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_pick('Erase and start over', 'امسح وابدأ من جديد')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _resetting = true);
    await _eraseLocalData();
    // Boot again from the top: migration creates a fresh key and empty boxes.
    await main();
  }

  Future<void> _eraseLocalData() async {
    try {
      await Hive.close();
    } catch (_) {}
    for (final name in HiveBoxes.all) {
      for (final candidate in [
        name,
        '${name}__encrypted_migration',
        '${name}__encrypted_target',
      ]) {
        try {
          await Hive.deleteBoxFromDisk(candidate);
        } catch (error) {
          debugPrint('Could not delete $candidate: $error');
        }
      }
    }
    try {
      final docs = await getApplicationDocumentsDirectory();
      for (final directoryName in ['images', 'audio']) {
        final directory = Directory('${docs.path}/$directoryName');
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    } catch (error) {
      debugPrint('Could not delete media: $error');
    }
    await EncryptionService().deleteKey();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Directionality(
          textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 56),
                    const SizedBox(height: 20),
                    Text(
                      _pick('Secure storage could not be opened.',
                          'تعذّر فتح التخزين الآمن.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _pick(
                        'Your data was not changed. Restart the app first. If '
                            'this keeps happening, you can start over and '
                            'restore a backup.',
                        'لم تتغير بياناتك. أعد تشغيل التطبيق أولًا، وإذا تكرر '
                            'هذا يمكنك البدء من جديد واستعادة نسخة احتياطية.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (_resetting)
                      const CircularProgressIndicator()
                    else
                      OutlinedButton.icon(
                        onPressed: () => _confirmReset(context),
                        icon: const Icon(Icons.restart_alt),
                        label: Text(_pick('Start over', 'البدء من جديد')),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
