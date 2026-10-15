import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nabd/services/monetization_service.dart';

class _MemoryStore implements EntitlementStore {
  _MemoryStore(this.value);

  CachedEntitlement? value;

  @override
  Future<CachedEntitlement?> read() async => value;

  @override
  Future<void> write(CachedEntitlement entitlement) async =>
      value = entitlement;
}

/// Answers the store with whatever each test needs, including the empty answer
/// a refunded purchase leaves behind.
class _FakeBilling extends InAppPurchasePlatform {
  final StreamController<List<PurchaseDetails>> _updates =
      StreamController<List<PurchaseDetails>>.broadcast();

  List<PurchaseDetails> owned = const [];
  bool storeFails = false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async =>
      ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: identifiers.toList(),
      );

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    if (storeFails) {
      throw InAppPurchaseException(
        source: 'fake',
        code: 'BILLING_UNAVAILABLE',
        message: 'the store did not answer',
      );
    }
    _updates.add(owned);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}

PurchaseDetails _lifetimePurchase() => PurchaseDetails(
      productID: MonetizationConfig.lifetimeId,
      purchaseID: 'fake-order-1',
      transactionDate: null,
      status: PurchaseStatus.restored,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'fake',
      ),
    );

void main() {
  group('cached entitlement', () {
    final now = DateTime(2026, 10, 3, 12);

    test('lifetime is active forever', () {
      const cached = CachedEntitlement(lifetime: true);
      expect(cached.isActive(now), isTrue);
      expect(cached.isActive(now.add(const Duration(days: 3650))), isTrue);
    });

    test('a subscription is active only until its expiry', () {
      final cached =
          CachedEntitlement(proExpiry: now.add(const Duration(days: 2)));
      expect(cached.isActive(now), isTrue);
      expect(cached.isActive(now.add(const Duration(days: 3))), isFalse);
    });

    test('nothing cached grants nothing', () {
      expect(const CachedEntitlement().isActive(now), isFalse);
    });

    test('round-trips through the stored JSON', () {
      final original = CachedEntitlement(
        lifetime: false,
        proExpiry: now.add(const Duration(days: 30)),
      );
      final restored =
          CachedEntitlement.tryParse(jsonEncode(original.toJson()))!;
      expect(restored.lifetime, isFalse);
      expect(restored.proExpiry, original.proExpiry);
    });

    test('a corrupted cache is ignored instead of granting Pro', () {
      expect(CachedEntitlement.tryParse('not json'), isNull);
      expect(CachedEntitlement.tryParse('[1,2]'), isNull);
      expect(CachedEntitlement.tryParse(null), isNull);
      expect(
        CachedEntitlement.tryParse('{"lifetime":"yes"}')!.isActive(now),
        isFalse,
      );
    });
  });

  group('when the store stops owning the purchase', () {
    late _FakeBilling billing;

    setUp(() {
      billing = _FakeBilling();
      InAppPurchasePlatform.instance = billing;
    });

    Future<(MonetizationService, _MemoryStore)> start(
      List<PurchaseDetails> owned, {
      bool storeFails = false,
    }) async {
      billing
        ..owned = owned
        ..storeFails = storeFails;
      final store = _MemoryStore(const CachedEntitlement(lifetime: true));
      final service = MonetizationService(store: store);
      await pumpEventQueue();
      return (service, store);
    }

    test('a refund takes Pro away and clears the cache', () async {
      final (service, store) = await start(const []);

      expect(service.state.isPro, isFalse);
      expect(service.state.isLifetime, isFalse);
      expect(service.state.entitlementStatus, EntitlementStatus.expired);
      expect(store.value!.isActive(DateTime.now()), isFalse);

      service.dispose();
    });

    test('a purchase the store still reports keeps Pro', () async {
      final (service, store) = await start([_lifetimePurchase()]);

      expect(service.state.isPro, isTrue);
      expect(service.state.entitlementStatus, EntitlementStatus.lifetime);
      expect(store.value!.lifetime, isTrue);

      service.dispose();
    });

    test('a store that never answers keeps Pro', () async {
      final (service, store) = await start(const [], storeFails: true);

      expect(service.state.isPro, isTrue);
      expect(store.value!.lifetime, isTrue);

      service.dispose();
    });

    test('a buyer with nothing cached stays without Pro', () async {
      final service = MonetizationService(
        store: _MemoryStore(const CachedEntitlement()),
      );
      await pumpEventQueue();

      expect(service.state.isPro, isFalse);

      service.dispose();
    });
  });
}
