// Every main screen must lay out at the largest system text size without
// overflowing: people who need big text should not lose buttons or labels.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/core/storage.dart';
import 'package:nabd/core/theme/app_theme.dart';
import 'package:nabd/core/theme/gender_themes.dart';
import 'package:nabd/features/editor/editor_screen.dart';
import 'package:nabd/features/garden/garden_screen.dart';
import 'package:nabd/features/garden/seed_selection_screen.dart';
import 'package:nabd/features/journal/journal_screen.dart';
import 'package:nabd/features/personal/letters_screen.dart';
import 'package:nabd/features/practice/practice_screen.dart';
import 'package:nabd/features/settings/settings_screen.dart';
import 'package:nabd/features/stats/stats_screen.dart';
import 'package:nabd/features/today/today_screen.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/services/database_service.dart';
import 'package:nabd/services/monetization_service.dart';
import 'package:nabd/widgets/nabd_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

Widget _app(Widget home, Locale locale, {double scale = 2.0}) {
  final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => home)]);
  return ProviderScope(
    overrides: [
      monetizationProvider.overrideWith((_) => MonetizationService.preset(
          const MonetizationState(storeAvailable: true, productsLoaded: true))),
    ],
    child: MaterialApp.router(
      theme: AppTheme.getTheme('light', GenderTheme.neutral),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    ),
  );
}

void main() {
  late Directory dir;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Pulse',
      packageName: 'com.nabd.journal',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await initializeDateFormatting();
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nabd_large_text');
    Hive.init(dir.path);
    for (final name in HiveBoxes.all) {
      await Hive.openBox<dynamic>(name);
    }
    await Hive.box(HiveBoxes.settings).put('ui_sounds_enabled', false);
    final now = DateTime.now();
    for (var i = 0; i < 4; i++) {
      final at = now.subtract(Duration(days: i));
      await Hive.box(HiveBoxes.journal).put('e$i', JournalEntry(
        id: 'e$i',
        title: 'A fairly long entry title number $i',
        content: 'Some words about the day, long enough to wrap twice.',
        mood: i.isEven ? 'happy' : 'sad',
        tags: const ['family'],
        createdAt: at,
        updatedAt: at,
      ).toMap());
    }
    DatabaseService.invalidate();
  });

  tearDown(() async {
    await Hive.close();
    DatabaseService.invalidate();
    await dir.delete(recursive: true);
  });

  final screens = <String, Widget Function()>{
    'today': () => const TodayScreen(),
    'journal': () => const JournalScreen(),
    'practice': () => const PracticeScreen(),
    'insights': () => const StatsScreen(),
    'editor': () => const EditorScreen(entryId: 'e0'),
    'settings': () => const SettingsScreen(),
    'garden': () => const GardenScreen(),
    'letters': () => const LettersScreen(),
  };

  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final MapEntry(key: name, value: build) in screens.entries) {
      testWidgets('$name lays out at 200% text (${locale.languageCode})',
          (tester) async {
        // A small phone: 360 x 740 dp.
        tester.view.physicalSize = const Size(1080, 2220);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(build(), locale));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final error = tester.takeException();
        if (error != null) {
          void visit(RenderObject node) {
            final line = node.toStringShort();
            if (line.contains('OVERFLOWING')) {
              debugPrint('OVERFLOW: $line  <- ${node.debugCreator}');
            }
            node.visitChildren(visit);
          }
          visit(tester.renderObject(find.byType(MaterialApp)));
        }
        expect(error, isNull);
      });
    }
  }

  // The seed cards: a real phone clipped the "Hope" card by 2 px at normal
  // text size, so check the grid at 100% as well as 200%.
  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('seed choice lays out at ${(scale * 100).round()}% text '
          '(${locale.languageCode})', (tester) async {
        tester.view.physicalSize = const Size(1080, 2220);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
            _app(const SeedSelectionScreen(), locale, scale: scale));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.ensureVisible(find.byType(FilledButton).first);
        await tester.pump();
        await tester.tap(find.byType(FilledButton).first);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(EqualHeightGrid), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
