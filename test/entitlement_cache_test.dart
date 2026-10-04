import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/monetization_service.dart';

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
}
