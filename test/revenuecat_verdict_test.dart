import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/monetization_service.dart';

Map<String, dynamic> _body(Map<String, dynamic> entitlements) => {
      'subscriber': {'entitlements': entitlements},
    };

void main() {
  final now = DateTime.utc(2026, 10, 6, 12);

  test('an entitlement expiring later is an active subscription', () {
    final result = revenueCatVerdict(
      _body({
        'pro': {'expires_date': '2026-11-06T12:00:00Z'},
      }),
      entitlement: 'pro',
      now: now,
    );
    expect(result.status, EntitlementStatus.subscriptionActive);
    expect(result.isPro, isTrue);
    expect(result.expiryDate!.toUtc(), DateTime.utc(2026, 11, 6, 12));
  });

  test('a lapsed entitlement is expired, which is a verdict', () {
    final result = revenueCatVerdict(
      _body({
        'pro': {'expires_date': '2026-09-06T12:00:00Z'},
      }),
      entitlement: 'pro',
      now: now,
    );
    expect(result.status, EntitlementStatus.expired);
    expect(result.isPro, isFalse);
  });

  test('a billing grace period keeps Pro until it ends', () {
    final result = revenueCatVerdict(
      _body({
        'pro': {
          'expires_date': '2026-10-05T12:00:00Z',
          'grace_period_expires_date': '2026-10-12T12:00:00Z',
        },
      }),
      entitlement: 'pro',
      now: now,
    );
    expect(result.status, EntitlementStatus.subscriptionActive);
    expect(result.expiryDate!.toUtc(), DateTime.utc(2026, 10, 12, 12));
  });

  test('no expiry means a lifetime unlock', () {
    final result = revenueCatVerdict(
      _body({
        'pro': {'expires_date': null},
      }),
      entitlement: 'pro',
      now: now,
    );
    expect(result.status, EntitlementStatus.lifetime);
  });

  test('a missing entitlement is a setup error, never a verdict', () {
    for (final body in [
      _body({}),
      _body({'other': {'expires_date': null}}),
      <String, dynamic>{},
      <String, dynamic>{'subscriber': 'nonsense'},
    ]) {
      final result = revenueCatVerdict(body, entitlement: 'pro', now: now);
      expect(result.status, EntitlementStatus.error);
      expect(result.isPro, isFalse);
    }
  });

  test('without a key or backend, subscriptions stay hidden', () {
    // Tests build without --dart-define, like a build with nothing set up.
    expect(RevenueCatConfig.isConfigured, isFalse);
    expect(MonetizationConfig.subscriptionsEnabled, isFalse);
    expect(MonetizationConfig.productIds, {MonetizationConfig.lifetimeId});
    expect(MonetizationConfig.lifetimeId, 'nabd_lifetime');
  });
}
