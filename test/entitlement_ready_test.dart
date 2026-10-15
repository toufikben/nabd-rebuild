import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
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

  setUpAll(() {
    // `InAppPurchase.instance` registers a real platform client the first time
    // it is used, and the test binding claims Android. A neutral target keeps
    // the fakes below as the only billing code the service can reach.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  });

  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  setUp(() => InAppPurchasePlatform.instance = _UnavailableBilling());

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
