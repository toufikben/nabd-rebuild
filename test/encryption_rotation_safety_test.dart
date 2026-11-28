import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/encryption_service.dart';
import 'package:nabd/services/monetization_service.dart';

void main() {
  group('key rotation contract', () {
    test('refuses to rotate when no encrypted box is open', () async {
      // Rotation must never fall back to "delete everything and hope".
      // With nothing staged it has to fail loudly instead. The exact type
      // also proves this is no longer the old UnsupportedError stub.
      await expectLater(
        EncryptionService().rotateKey(),
        throwsA(
          isA<KeyRotationException>().having(
            (error) => error.message,
            'message',
            contains('nothing to rotate'),
          ),
        ),
      );
    });
  });

  group('monetization product configuration', () {
    test('has non-empty defaults', () {
      expect(MonetizationConfig.monthlyId, isNotEmpty);
      expect(MonetizationConfig.yearlyId, isNotEmpty);
      expect(MonetizationConfig.lifetimeId, isNotEmpty);
    });

    test('knows exactly three product ids', () {
      expect(MonetizationConfig.allProductIds, hasLength(3));
    });

    test('does not sell subscriptions without a verification backend', () {
      // Tests build without SUBSCRIPTION_VERIFICATION_BACKEND_URL.
      expect(MonetizationConfig.subscriptionsEnabled, isFalse);
      expect(MonetizationConfig.productIds, {MonetizationConfig.lifetimeId});
    });
  });

  group('server-side entitlement verdicts', () {
    VerificationResult parse(Map<String, dynamic> json) =>
        VerificationResult.fromJson(json);

    test('an active subscription grants Pro', () {
      final result = parse({
        'status': 'active',
        'expiryDate': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
      });

      expect(result.status, EntitlementStatus.subscriptionActive);
      expect(result.isPro, isTrue);
      expect(result.expiryDate, isNotNull);
    });

    test('an elapsed expiry date is treated as expired, not active', () {
      final result = parse({
        'status': 'active',
        'expiryDate': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      });

      expect(result.status, EntitlementStatus.expired);
      expect(result.isPro, isFalse);
    });

    test('lifetime grants Pro', () {
      final result = parse({'status': 'lifetime'});

      expect(result.status, EntitlementStatus.lifetime);
      expect(result.isPro, isTrue);
    });

    test('an unverified verdict never grants Pro', () {
      final result = parse({'status': 'unverified'});

      expect(result.status, EntitlementStatus.subscriptionUnverified);
      expect(result.isPro, isFalse);
    });

    test('an unrecognised payload never grants Pro', () {
      final result = parse({'status': 'something-else'});

      expect(result.status, EntitlementStatus.unknown);
      expect(result.isPro, isFalse);
    });

    test('an explicit error never grants Pro', () {
      final result = parse({'status': 'error', 'errorMessage': 'boom'});

      expect(result.status, EntitlementStatus.error);
      expect(result.isPro, isFalse);
      expect(result.errorMessage, 'boom');
    });

    test('a wrongly typed answer never throws', () {
      // The old parser used `as String` on these fields. A backend (or a proxy
      // in front of it) sending a number or a list took the whole entitlement
      // check down. An unparseable expiry now reads as no expiry, the same as
      // if the field had been absent — policy is unchanged, only the crash is
      // gone. An unreadable status still falls back to `unknown`.
      expect(parse({'status': 42}).status, EntitlementStatus.unknown);
      expect(parse({'status': ['active']}).status, EntitlementStatus.unknown);
      final badExpiry =
          parse({'status': 'active', 'expiryDate': ['not a date']});
      expect(badExpiry.status, EntitlementStatus.subscriptionActive);
      expect(badExpiry.expiryDate, isNull);
      final withError = parse({'status': 'error', 'errorMessage': 500});
      expect(withError.status, EntitlementStatus.error);
      expect(withError.errorMessage, isNull);
    });
  });
}
