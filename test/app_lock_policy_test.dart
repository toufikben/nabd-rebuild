import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/biometric_service.dart';

void main() {
  group('AppLockPolicy', () {
    late DateTime now;
    late AppLockPolicy policy;

    setUp(() {
      now = DateTime(2026, 9, 20, 12);
      policy = AppLockPolicy(now: () => now);
    });

    test('disabled lock never requires authentication', () {
      expect(
        policy.shouldShowLock(
          enabled: false,
          timeoutMinutes: 5,
          coldStart: true,
        ),
        isFalse,
      );
      policy.markBackgrounded();
      now = now.add(const Duration(hours: 1));
      expect(
        policy.shouldShowLock(enabled: false, timeoutMinutes: 5),
        isFalse,
      );
    });

    test('enabled lock requires authentication on cold start', () {
      expect(
        policy.shouldShowLock(
          enabled: true,
          timeoutMinutes: 5,
          coldStart: true,
        ),
        isTrue,
      );
    });

    test('enabling during an open session does not lock immediately', () {
      policy.setLockEnabled(true);
      expect(
        policy.shouldShowLock(
          enabled: true,
          timeoutMinutes: 5,
          coldStart: true,
        ),
        isFalse,
      );
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 5),
        isFalse,
      );
    });

    test('background shorter than timeout does not lock', () {
      policy.markColdStartComplete();
      policy.markBackgrounded();
      now = now.add(const Duration(minutes: 4, seconds: 59));
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 5),
        isFalse,
      );
    });

    test('background at or beyond timeout locks', () {
      policy.markColdStartComplete();
      policy.markBackgrounded();
      now = now.add(const Duration(minutes: 5));
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 5),
        isTrue,
      );
      now = now.add(const Duration(minutes: 1));
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 5),
        isTrue,
      );
    });

    test('Never prevents background lock', () {
      policy.markColdStartComplete();
      policy.markBackgrounded();
      now = now.add(const Duration(days: 2));
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 0),
        isFalse,
      );
    });

    test('disable clears background state and prevents future locks', () {
      policy.markColdStartComplete();
      policy.markBackgrounded();
      policy.setLockEnabled(false);
      now = now.add(const Duration(hours: 1));
      expect(
        policy.shouldShowLock(enabled: false, timeoutMinutes: 5),
        isFalse,
      );
      policy.setLockEnabled(true);
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 5),
        isFalse,
      );
    });

    test('failed authentication leaves the background lock pending', () {
      policy.markColdStartComplete();
      policy.markBackgrounded();
      now = now.add(const Duration(minutes: 5));
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 5),
        isTrue,
      );
      // A failed authentication does not call updateLastActivity.
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 5),
        isTrue,
      );
    });

    test('successful authentication clears background state', () {
      policy.markColdStartComplete();
      policy.markBackgrounded();
      now = now.add(const Duration(minutes: 5));
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 5),
        isTrue,
      );
      policy.updateLastActivity();
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 5),
        isFalse,
      );
    });

    test('normal navigation without background does not lock', () {
      policy.markColdStartComplete();
      expect(
        policy.shouldShowLock(enabled: true, timeoutMinutes: 5),
        isFalse,
      );
    });
  });
}
