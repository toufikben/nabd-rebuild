import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:nabd/services/monetization_service.dart';

/// Hands the cache back only when the test opens the gate, so a readiness
/// future that resolves before the read actually finished is caught.
class _GatedStore implements EntitlementStore {
  _GatedStore(this.cached);

  final CachedEntitlement? cached;
  final Completer<void> gate = Completer<void>();

  @override
  Future<CachedEntitlement?> read() async {
    await gate.future;
    return cached;
  }

  @override
  Future<void> write(CachedEntitlement entitlement) async {}
}

class _UnavailableBilling extends InAppPurchasePlatform {
  @override
  Future<bool> isAvailable() async => false;
}

/// Never answers, so a readiness future that waited for the billing client
/// would hang instead of resolving.
class _HangingBilling extends InAppPurchasePlatform {
  final Completer<bool> gate = Completer<bool>();

  @override
  Future<bool> isAvailable() => gate.future;
}

void main() {
  // The launch path reaches `InAppPurchase.instance`, which reads the
  // platform through the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Resolve the wrapper *before* the fake goes in: the test binding reports
    // Android, so that first touch registers the real billing client, and the
    // fake installed afterwards is the one that stays.
    final reused = identical(InAppPurchase.instance, InAppPurchase.instance);
    expect(reused, isTrue);
    InAppPurchasePlatform.instance = _UnavailableBilling();
  });

  test('Pro is granted only after readiness', () async {
    final store = _GatedStore(const CachedEntitlement(lifetime: true));
    final service = MonetizationService(store: store);
    addTearDown(service.dispose);

    // The cold default a synchronous gate used to trust.
    expect(service.isProActive, isFalse);

    final ready = service.ensureReady();
    store.gate.complete();
    await ready;

    expect(service.isProActive, isTrue);
  });

  test('readiness does not wait for the billing client', () async {
    InAppPurchasePlatform.instance = _HangingBilling();
    final store = _GatedStore(const CachedEntitlement(lifetime: true));
    final service = MonetizationService(store: store);
    addTearDown(service.dispose);

    store.gate.complete();
    await service.ensureReady().timeout(const Duration(seconds: 5));

    expect(service.isProActive, isTrue);
  });

  test('an empty cache is ready too, so the gate never hangs', () async {
    final store = _GatedStore(null);
    final service = MonetizationService(store: store);
    addTearDown(service.dispose);

    store.gate.complete();
    await service.ensureReady().timeout(const Duration(seconds: 5));

    expect(service.isProActive, isFalse);
  });
}
