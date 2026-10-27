import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/core/l10n/app_strings.dart';
import 'package:nabd/features/billing/paywall_screen.dart';
import 'package:nabd/services/monetization_service.dart';

const _locale = Locale('en');

String _t(String key) => S.en[key]!;

/// The paywall on top of a frozen entitlement, so the states a store would
/// take minutes to reach are one line each.
Widget _paywall(MonetizationState state) {
  return ProviderScope(
    overrides: [
      monetizationProvider.overrideWith(
        (ref) => MonetizationService.preset(state),
      ),
    ],
    child: MaterialApp(
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const PaywallScreen(),
    ),
  );
}

void main() {
  testWidgets('a lifetime Pro sees the entitlement instead of the plans', (
    tester,
  ) async {
    await tester.pumpWidget(
      _paywall(
        const MonetizationState(
          isPro: true,
          isLifetime: true,
          storeAvailable: true,
          productsLoaded: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text(_t('settings.pro.active')), findsOneWidget);
    expect(find.text(_t('paywall.activeLifetime')), findsOneWidget);

    // Nothing to buy, and nothing to restore.
    expect(find.text(_t('paywall.lifetime')), findsNothing);
    expect(find.text(_t('paywall.yearly')), findsNothing);
    expect(find.text(_t('paywall.restore')), findsNothing);
  });

  testWidgets('a subscription shows the day it runs out', (tester) async {
    await tester.pumpWidget(
      _paywall(
        MonetizationState(
          isPro: true,
          storeAvailable: true,
          productsLoaded: true,
          proExpiry: DateTime(2027, 1, 31),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        _t('paywall.activeUntil').replaceAll('{date}', 'January 31, 2027'),
      ),
      findsOneWidget,
    );
    expect(find.text(_t('paywall.lifetime')), findsNothing);
  });

  testWidgets('without Pro the plans and the restore action stay', (
    tester,
  ) async {
    await tester.pumpWidget(_paywall(const MonetizationState()));
    await tester.pump();

    expect(find.text(_t('paywall.restore')), findsOneWidget);
    expect(find.text(_t('settings.pro.active')), findsNothing);
    // No store in the test, so the screen explains that instead of pricing.
    expect(find.text(_t('paywall.unavailable')), findsOneWidget);
  });
}
