import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/core/storage.dart';
import 'package:nabd/features/editor/editor_screen.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/services/database_service.dart';
import 'package:nabd/services/monetization_service.dart';

void main() {
  late Directory directory;

  setUpAll(() => initializeDateFormatting());

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nabd_editor');
    Hive.init(directory.path);
    for (final name in HiveBoxes.all) {
      await Hive.openBox<dynamic>(name);
    }
    DatabaseService.invalidate();
  });

  tearDown(() async {
    await Hive.close();
    DatabaseService.invalidate();
    await directory.delete(recursive: true);
  });

  Future<GoRouter> pumpEditor(WidgetTester tester, {String? id}) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/editor',
          builder: (_, state) =>
              EditorScreen(entryId: state.uri.queryParameters['id']),
        ),
        GoRoute(
          path: '/paywall',
          builder: (_, __) => const Scaffold(body: Text('paywall')),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        monetizationProvider.overrideWith(
          (_) => MonetizationService.preset(
            const MonetizationState(),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pump();
    router.push(id == null ? '/editor' : '/editor?id=$id');
    await tester.pumpAndSettle();
    return router;
  }

  Box entries() => Hive.box(HiveBoxes.journal);

  testWidgets('an autosave and a manual save make one entry, not two',
      (tester) async {
    await tester.runAsync(() async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField).at(1),
          'A long enough first entry for the day');
      // Let the 3 second autosave fire (a real timer inside runAsync).
      await Future<void>.delayed(const Duration(milliseconds: 3500));
      await tester.pump();
      expect(entries().length, 1);

      await tester.tap(find.byIcon(Icons.check_rounded));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(entries().length, 1);
      expect(find.text('home'), findsOneWidget);
    });
  });

  testWidgets('discard puts an edited entry back as it was', (tester) async {
    await tester.runAsync(() async {
      final original = JournalEntry(
        id: 'e1',
        title: 'Original title',
        content: 'original words',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );
      await entries().put('e1', original.toMap());

      await pumpEditor(tester, id: 'e1');
      await tester.enterText(
        find.byType(TextField).at(1),
        'rewritten words that autosave will store',
      );
      await Future<void>.delayed(const Duration(milliseconds: 3500));
      await tester.pump();
      expect(entries().get('e1')['content'],
          'rewritten words that autosave will store');

      // A further edit that autosave has not caught yet brings up the dialog.
      await tester.enterText(find.byType(TextField).at(1), 'second thoughts');
      await tester.pump();
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
      await navigator.maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(entries().get('e1')['content'], 'original words');
      expect(find.text('home'), findsOneWidget);
    });
  });

  testWidgets('a missing entry shows a notice instead of a blank editor',
      (tester) async {
    await pumpEditor(tester, id: 'gone');
    expect(find.text('This entry no longer exists'), findsOneWidget);
  });
}
