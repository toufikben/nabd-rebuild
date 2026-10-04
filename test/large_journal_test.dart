// A journal of years: 2000 entries must not build 2000 cards or stall the
// screens that summarise it.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/core/memories.dart';
import 'package:nabd/core/mood_patterns.dart';
import 'package:nabd/core/storage.dart';
import 'package:nabd/core/streak.dart';
import 'package:nabd/features/journal/journal_screen.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/services/database_service.dart';
import 'package:nabd/widgets/entry_card.dart';

const _count = 2000;

void main() {
  late Directory dir;

  setUpAll(() async {
    await initializeDateFormatting();
    dir = await Directory.systemTemp.createTemp('nabd_large_journal');
    Hive.init(dir.path);
    for (final name in HiveBoxes.all) {
      await Hive.openBox<dynamic>(name);
    }
    await Hive.box(HiveBoxes.settings).put('ui_sounds_enabled', false);
    final moods = ['happy', 'sad', 'peaceful', 'anxious', 'grateful'];
    final start = DateTime.now();
    await Hive.box(HiveBoxes.journal).putAll({
      for (var i = 0; i < _count; i++)
        'e$i': JournalEntry(
          id: 'e$i',
          title: 'Entry $i',
          content: 'A day of writing, number $i, with a few more words in it.',
          mood: moods[i % moods.length],
          tags: [if (i.isEven) 'family' else 'work'],
          createdAt: start.subtract(Duration(hours: 9 * i)),
          updatedAt: start.subtract(Duration(hours: 9 * i)),
        ).toMap(),
    });
    DatabaseService.invalidate();
  });

  tearDownAll(() async {
    await Hive.close();
    DatabaseService.invalidate();
    await dir.delete(recursive: true);
  });

  test('summaries over 2000 entries stay fast', () {
    final watch = Stopwatch()..start();
    final entries = DatabaseService().getAllEntries();
    expect(entries, hasLength(_count));
    StreakCalculator.current(entries.map((e) => e.createdAt));
    StreakCalculator.longest(entries.map((e) => e.createdAt));
    Memories.onThisDay(entries, DateTime.now());
    final patterns = MoodPatterns.compute(entries);
    expect(patterns.hasEnough, isTrue);
    // Generous: catches an accidental quadratic, not a slow CI machine.
    expect(watch.elapsedMilliseconds, lessThan(3000));
  });

  testWidgets('the journal builds only the cards on screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => const JournalScreen())]);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    final built = tester.widgetList(find.byType(EntryCard, skipOffstage: false)).length;
    expect(built, greaterThan(0));
    expect(built, lessThan(40), reason: 'built $built of $_count cards');
  });
}
