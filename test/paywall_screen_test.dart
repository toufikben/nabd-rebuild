import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/core/l10n/app_strings.dart';
import 'package:nabd/features/billing/paywall_screen.dart';
import 'package:nabd/services/monetization_service.dart';

const _locale = Locale('en');

String _t(String key) => S.en[key]!;

ProductDetails _product(String id, String price) => ProductDetails(
      id: id,
      title: id,
      description: '',
      price: price,
      rawPrice: 675,
      currencyCode: 'DZD',
    );

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

  testWidgets('a store error is not printed twice', (tester) async {
    // Play reports the load failure with the same sentence the card already
    // uses as its title, which used to render the line twice.
    await tester.pumpWidget(
      _paywall(
        MonetizationState(
          storeAvailable: true,
          productsLoaded: true,
          error: _t('paywall.loadFailed'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(_t('paywall.loadFailed')), findsOneWidget);
  });

  testWidgets('a store error with detail keeps both lines', (tester) async {
    await tester.pumpWidget(
      _paywall(
        const MonetizationState(
          storeAvailable: true,
          productsLoaded: true,
          error: 'Service unavailable (503)',
        ),
      ),
    );
    await tester.pump();

    expect(find.text(_t('paywall.loadFailed')), findsOneWidget);
    expect(find.text('Service unavailable (503)'), findsOneWidget);
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

  testWidgets('a subscriber can reach the store to cancel', (tester) async {
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

    // Only the store can end a subscription, so the screen hands the user to
    // it instead of pretending the app can cancel.
    expect(find.text(_t('paywall.manage')), findsOneWidget);
  });

  testWidgets('a lifetime owner has no subscription to manage', (
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

    expect(find.text(_t('paywall.manage')), findsNothing);
  });

  testWidgets('a plan the store did not return is not offered', (tester) async {
    // Play answers with the products that exist. The lifetime purchase is not
    // in the store yet, so the card that used to render with an empty price
    // and a dead tap is gone until the product is created.
    await tester.pumpWidget(
      _paywall(
        MonetizationState(
          storeAvailable: true,
          productsLoaded: true,
          products: [
            _product(MonetizationService.proMonthlyId, 'DZD 675.00'),
            _product(MonetizationService.proYearlyId, 'DZD 4,700.00'),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text(_t('paywall.monthly')), findsOneWidget);
    expect(find.text(_t('paywall.yearly')), findsOneWidget);
    expect(find.text(_t('paywall.lifetime')), findsNothing);
  });

  testWidgets('a store that returns nothing sellable explains itself', (
    tester,
  ) async {
    await tester.pumpWidget(
      _paywall(
        const MonetizationState(storeAvailable: true, productsLoaded: true),
      ),
    );
    await tester.pump();

    expect(find.text(_t('paywall.loadFailed')), findsOneWidget);
  });

  testWidgets('a failed restore says so instead of staying silent', (
    tester,
  ) async {
    // The store threw before it could answer, so there is nothing to restore
    // and no purchase event. The button used to look dead in this case.
    await tester.pumpWidget(
      _paywall(
        const MonetizationState(
          storeAvailable: true,
          productsLoaded: true,
          restoreFailed: true,
          error: 'Billing service unavailable',
        ),
      ),
    );
    await tester.pump();

    expect(find.text(_t('paywall.unavailableHint')), findsOneWidget);
  });
}
