import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/encryption_service.dart';
import 'package:nabd/services/monetization_service.dart';

void main() {
  group('key rotation contract', () {
    test('refuses to rotate when no encrypted box is open', () async {
      // Rotation must never fall back to "delete everything and hope".
      // With nothing staged it has to fail loudly instead.
      await expectLater(
        EncryptionService().rotateKey(),
        throwsA(isA<KeyRotationException>()),
      );
    });

    test('no longer advertises rotation as unsupported', () {
      // The old implementation threw UnsupportedError, which is what this
      // guard is protecting against regressing back to.
      expect(
        () => EncryptionService().rotateKey(),
        isNot(throwsA(isA<UnsupportedError>())),
      );
    });
  });

  group('monetization product configuration', () {
    test('has non-empty defaults', () {
      expect(MonetizationConfig.monthlyId, isNotEmpty);
      expect(MonetizationConfig.yearlyId, isNotEmpty);
      expect(MonetizationConfig.lifetimeId, isNotEmpty);
    });

    test('exposes exactly three product ids', () {
      expect(MonetizationConfig.productIds, hasLength(3));
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
  });
}
