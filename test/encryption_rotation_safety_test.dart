import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/encryption_service.dart';
import 'package:nabd/services/monetization_service.dart';

void main() {
  test('unsafe key rotation is disabled rather than replacing the key', () {
    expect(
      () => EncryptionService().rotateKey(),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('monetization product configuration has non-empty defaults', () {
    expect(MonetizationConfig.monthlyId, isNotEmpty);
    expect(MonetizationConfig.yearlyId, isNotEmpty);
    expect(MonetizationConfig.lifetimeId, isNotEmpty);
  });
}
