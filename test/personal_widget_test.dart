import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/features/personal/echoes_screen.dart';
import 'package:nabd/features/personal/sage_screen.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/services/r_personal_service.dart';

Widget _testApp(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

JournalEntry _entry({
  required String id,
  required DateTime createdAt,
  required String mood,
  required String content,
}) {
  return JournalEntry(
    id: id,
    title: id,
    content: content,
    createdAt: createdAt,
    updatedAt: createdAt,
    mood: mood,
  );
}

class _FakePersonalService extends RPersonalService {
  _FakePersonalService(this.echoes);

  final List<EchoRecord> echoes;

  @override
  Future<List<EchoRecord>> loadEchoes() async => echoes;
}

void main() {
  group('EchoesScreen widget tests', () {
    testWidgets('shows the localized empty state in Arabic', (tester) async {
      await tester.pumpWidget(
        _testApp(
          EchoesScreen(service: _FakePersonalService(const [])),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('أصداء'), findsOneWidget);
      expect(
        find.text(
          'تظهر الأصداء عندما يتبع مزاج صعب مدخلة إيجابية بعد 3 إلى 90 يومًا.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders resolved mood emoji, localized mood, and entries',
        (tester) async {
      final originalDate = DateTime(2026, 1, 1, 12);
      final original = _entry(
        id: 'original',
        createdAt: originalDate,
        mood: 'sad',
        content: 'A difficult day',
      );
      final resolution = _entry(
        id: 'positive',
        createdAt: originalDate.add(const Duration(days: 3)),
        mood: 'happy',
        content: 'A hopeful response',
      );

      await tester.pumpWidget(
        _testApp(
          EchoesScreen(
            service: _FakePersonalService([
              EchoRecord(original: original, resolution: resolution),
            ]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Resolved echo'), findsOneWidget);
      expect(find.text('😢'), findsOneWidget);
      expect(find.text('Sad'), findsOneWidget);
      expect(find.text('A difficult day'), findsOneWidget);
      expect(find.text('Later positive entry'), findsOneWidget);
      expect(find.text('A hopeful response'), findsOneWidget);
    });
  });

  group('SageScreen widget tests', () {
    testWidgets('shows localized title, supporting copy, and local quote',
        (tester) async {
      await tester.pumpWidget(
        _testApp(const SageScreen(), locale: const Locale('ar')),
      );
      await tester.pump();

      expect(find.text('الحكيم'), findsOneWidget);
      expect(find.text('فكرة هادئة'), findsOneWidget);
      expect(
        find.text(
          'يعتمد الحكيم على مكتبة المحتوى المحلية في التطبيق، ولا يتغير إلا عند الضغط على تحديث.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('changes the quote when Refresh is pressed', (tester) async {
      await tester.pumpWidget(_testApp(const SageScreen()));
      await tester.pump();

      final quoteFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data?.startsWith('«') == true,
      );
      final before = tester.widget<Text>(quoteFinder).data;

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump();

      final after = tester.widget<Text>(quoteFinder).data;
      expect(after, isNot(before));
    });
  });
}
