// ignore_for_file: invalid_use_of_visible_for_testing_member
// Renders the main screens to PNG files for a visual review of the design.
// Not part of the normal test run:
//   flutter test tool/screenshots_test.dart --dart-define=SHOTS_DIR=/some/dir
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/core/storage.dart';
import 'package:nabd/core/theme/app_colors.dart';
import 'package:nabd/core/theme/app_theme.dart';
import 'package:nabd/core/theme/gender_themes.dart';
import 'package:nabd/features/billing/paywall_screen.dart';
import 'package:nabd/features/editor/editor_screen.dart';
import 'package:nabd/features/journal/journal_screen.dart';
import 'package:nabd/features/practice/practice_screen.dart';
import 'package:nabd/features/shell/app_shell.dart';
import 'package:nabd/features/stats/stats_screen.dart';
import 'package:nabd/features/settings/settings_screen.dart';
import 'package:nabd/features/garden/garden_screen.dart';
import 'package:nabd/features/garden/seed_selection_screen.dart';
import 'package:nabd/features/personal/letters_screen.dart';
import 'package:nabd/features/today/today_screen.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/services/database_service.dart';
import 'package:nabd/services/monetization_service.dart';

const _shotsDir = String.fromEnvironment('SHOTS_DIR', defaultValue: 'build/shots');

Future<void> _loadFonts() async {
  final family = FontLoader(GenderThemes.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/IBMPlexSansArabic-$weight.ttf').readAsBytesSync();
    family.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await family.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final icons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

Future<void> _seed() async {
  final journal = Hive.box(HiveBoxes.journal);
  final now = DateTime.now();
  final samples = [
    ('يوم على البحر', 'مشيت طويلًا على الشاطئ وشعرت أن الهواء يغسل التعب. أريد أن أتذكر هذا الهدوء.', 'peaceful', 0),
    ('رسالة من أمي', 'اتصلت أمي في الصباح وضحكنا كثيرًا. ممتن لهذه اللحظات الصغيرة.', 'grateful', 1),
    ('اجتماع صعب', 'كان الاجتماع متوترًا، لكنني قلت ما أريد بهدوء. فخور بنفسي قليلًا.', 'anxious', 2),
    ('A quiet evening', 'Read a few pages and made tea. Nothing special, and that felt good.', 'happy', 4),
  ];
  for (var i = 0; i < samples.length; i++) {
    final (title, content, mood, daysAgo) = samples[i];
    final at = now.subtract(Duration(days: daysAgo, hours: i));
    await journal.put('s$i', JournalEntry(
      id: 's$i',
      title: title,
      content: content,
      mood: mood,
      createdAt: at,
      updatedAt: at,
      isPinned: i == 1,
      tags: i == 0 ? const ['travel'] : const [],
    ).toMap());
  }
  DatabaseService.invalidate();
}

Widget _app(Widget home, {required Locale locale, required Brightness brightness, bool shell = false}) {
  AppColors.brightness = brightness;
  final router = GoRouter(
    initialLocation: '/',
    routes: shell
        ? [
            StatefulShellRoute.indexedStack(
              builder: (_, __, shell) => AppShell(navigationShell: shell),
              branches: [
                StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, __) => home)]),
                StatefulShellBranch(routes: [GoRoute(path: '/journal', builder: (_, __) => const SizedBox())]),
                StatefulShellBranch(routes: [GoRoute(path: '/sessions', builder: (_, __) => const SizedBox())]),
                StatefulShellBranch(routes: [GoRoute(path: '/garden', builder: (_, __) => const SizedBox())]),
                StatefulShellBranch(routes: [GoRoute(path: '/stats', builder: (_, __) => const SizedBox())]),
              ],
            ),
          ]
        : [GoRoute(path: '/', builder: (_, __) => home)],
  );
  return ProviderScope(
    overrides: [
      monetizationProvider.overrideWith(
        (_) => MonetizationService.preset(const MonetizationState(
          storeAvailable: true,
          productsLoaded: true,
        )),
      ),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme('light', GenderTheme.neutral),
      darkTheme: AppTheme.getTheme('dark', GenderTheme.neutral),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  final element = tester.element(find.byType(MaterialApp));
  final boundary = element.findRenderObject()!;
  RenderObject? node = boundary;
  while (node != null && node is! RenderRepaintBoundary) {
    node = node.parent;
  }
  final repaint = node as RenderRepaintBoundary? ??
      tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
  final image = await repaint.toImage(pixelRatio: 1);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('$_shotsDir/$name.png')..createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Nabd',
      packageName: 'com.nabd.journal',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await initializeDateFormatting();
    await _loadFonts();
  });

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('nabd_shots');
    Hive.init(hiveDir.path);
    for (final name in HiveBoxes.all) {
      await Hive.openBox<dynamic>(name);
    }
    await _seed();
  });

  tearDown(() async {
    await Hive.close();
    DatabaseService.invalidate();
    await hiveDir.delete(recursive: true);
  });

  final screens = <String, (Widget, bool)>{
    'today': (const TodayScreen(), true),
    'journal': (const JournalScreen(), false),
    'practice': (const PracticeScreen(), false),
    'insights': (const StatsScreen(), false),
    'editor': (const EditorScreen(entryId: 's0'), false),
    'paywall': (const PaywallScreen(), false),
    'settings': (const SettingsScreen(), false),
    'garden': (const GardenScreen(), false),
    'seeds': (const SeedSelectionScreen(), false),
    'letters': (const LettersScreen(), false),
  };

  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final brightness in Brightness.values) {
      for (final entry in screens.entries) {
        final name = '${entry.key}_${locale.languageCode}_${brightness.name}';
        testWidgets(name, (tester) async {
          tester.view.physicalSize = const Size(1080, 2340);
          tester.view.devicePixelRatio = 2.75;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(RepaintBoundary(
            child: _app(entry.value.$1,
                locale: locale, brightness: brightness, shell: entry.value.$2),
          ));
          // Let async loads (platform mocks) finish, then run animations on
          // the test clock so entrance effects have played.
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 300)));
          for (var i = 0; i < 30; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          await tester.runAsync(() => _capture(tester, name));
        });
      }
    }
  }
}
