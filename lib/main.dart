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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await DatabaseMigrationService().migrate();
  await Hive.openBox('journal_entries');
  await Hive.openBox('settings');
  await Hive.openBox('moods');
  await Hive.openBox('tags');
  await Hive.openBox('garden');

  await NotificationService.init();
  await SettingsService.init();
  await EncryptionService().initialize();
  await MobileAds.instance.initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: NabdApp()));
}
