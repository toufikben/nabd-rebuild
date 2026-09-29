import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/features/lock/passcode_pad.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

Finder _digit(int value) => find.byKey(ValueKey<int>(value));

void main() {
  testWidgets('submit stays closed until four digits are entered',
      (WidgetTester tester) async {
    String? submitted;
    await tester.pumpWidget(_testApp(
      PasscodePad(onSubmit: (pin) => submitted = pin),
    ));

    expect(tester.widget<ElevatedButton>(find.byKey(const ValueKey('submit')))
        .onPressed, isNull);

    for (final digit in [1, 2, 3]) {
      await tester.tap(_digit(digit));
    }
    expect(submitted, isNull);
    expect(tester.widget<ElevatedButton>(find.byKey(const ValueKey('submit')))
        .onPressed, isNull);

    await tester.tap(_digit(4));
    expect(
      tester.widget<ElevatedButton>(find.byKey(const ValueKey('submit')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('submit reports the digits that were entered',
      (WidgetTester tester) async {
    String? submitted;
    await tester.pumpWidget(_testApp(
      PasscodePad(onSubmit: (pin) => submitted = pin),
    ));

    for (final digit in [4, 7, 8, 9]) {
      await tester.tap(_digit(digit));
    }
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pump();

    expect(submitted, '4789');
  });

  testWidgets('backspace removes the last digit', (WidgetTester tester) async {
    String? submitted;
    await tester.pumpWidget(_testApp(
      PasscodePad(onSubmit: (pin) => submitted = pin),
    ));

    for (final digit in [1, 2, 3, 4]) {
      await tester.tap(_digit(digit));
    }
    await tester.tap(find.byKey(const ValueKey('backspace')));
    await tester.pump();

    expect(
      tester.widget<ElevatedButton>(find.byKey(const ValueKey('submit')))
          .onPressed,
      isNull,
    );

    await tester.tap(_digit(5));
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pump();

    expect(submitted, '1235');
  });

  testWidgets('a seventh digit is ignored', (WidgetTester tester) async {
    String? submitted;
    await tester.pumpWidget(_testApp(
      PasscodePad(onSubmit: (pin) => submitted = pin),
    ));

    for (final digit in [1, 2, 3, 4, 5, 6, 7]) {
      await tester.tap(_digit(digit));
    }
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pump();

    expect(submitted, '123456');
  });

  testWidgets('a locked pad takes no input and states the wait',
      (WidgetTester tester) async {
    String? submitted;
    await tester.pumpWidget(_testApp(
      PasscodePad(
        onSubmit: (pin) => submitted = pin,
        locked: true,
        remainingSeconds: 30,
      ),
    ));

    expect(find.textContaining('30'), findsWidgets);

    await tester.tap(_digit(1));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pump();

    expect(submitted, isNull);
  });

  testWidgets('the pad offers the recovery route only when told to',
      (WidgetTester tester) async {
    var forgotTaps = 0;
    await tester.pumpWidget(_testApp(
      PasscodePad(onSubmit: (_) {}, onForgotTap: () => forgotTaps++),
    ));
    expect(find.byKey(const ValueKey('forgot')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('forgot')));
    await tester.pump();
    expect(forgotTaps, 1);

    await tester.pumpWidget(_testApp(PasscodePad(onSubmit: (_) {})));
    expect(find.byKey(const ValueKey('forgot')), findsNothing);
  });

  testWidgets('the entry is hidden behind dots, not digits',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp(PasscodePad(onSubmit: (_) {})));

    for (final digit in [4, 7, 8, 9]) {
      await tester.tap(_digit(digit));
    }
    await tester.pump();

    // The keys on the pad print their own digit; nothing may print the pin the
    // user has built up, or a shoulder can read it.
    for (final label in tester.widgetList<Text>(find.byType(Text))) {
      expect(label.data?.contains('4789'), isNot(isTrue),
          reason: 'the pad painted the entered pin as text');
    }
  });
}
