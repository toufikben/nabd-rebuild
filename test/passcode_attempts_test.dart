import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/passcode_service.dart';

void main() {
  late DateTime now;
  late PasscodeAttempts attempts;

  setUp(() {
    now = DateTime(2026, 9, 29, 12);
    attempts = PasscodeAttempts(now: () => now);
  });

  test('a fresh throttle allows an attempt', () {
    expect(attempts.isLocked(), isFalse);
    expect(attempts.remainingSeconds(), 0);
  });

  test('four failures still allow another try', () {
    for (var i = 0; i < 4; i++) {
      attempts.recordFailure();
    }
    expect(attempts.isLocked(), isFalse);
    expect(attempts.failures, 4);
  });

  test('the fifth failure locks the pad for 30 seconds', () {
    for (var i = 0; i < 5; i++) {
      attempts.recordFailure();
    }
    expect(attempts.isLocked(), isTrue);
    expect(attempts.remainingSeconds(), 30);
  });

  test('a failure while locked does not extend the wait', () {
    for (var i = 0; i < 6; i++) {
      attempts.recordFailure();
    }
    now = now.add(const Duration(seconds: 10));
    expect(attempts.remainingSeconds(), 20);
  });

  test('the lock expires by itself', () {
    for (var i = 0; i < 5; i++) {
      attempts.recordFailure();
    }
    now = now.add(const Duration(seconds: 30));
    expect(attempts.isLocked(), isFalse);
    expect(attempts.failures, 0);
  });

  test('a fresh batch of failures is needed after the wait', () {
    for (var i = 0; i < 5; i++) {
      attempts.recordFailure();
    }
    now = now.add(const Duration(seconds: 31));
    for (var i = 0; i < 4; i++) {
      attempts.recordFailure();
    }
    expect(attempts.isLocked(), isFalse);
  });

  test('a successful unlock clears the count', () {
    for (var i = 0; i < 4; i++) {
      attempts.recordFailure();
    }
    attempts.recordSuccess();
    expect(attempts.failures, 0);
    for (var i = 0; i < 4; i++) {
      attempts.recordFailure();
    }
    expect(attempts.isLocked(), isFalse);
  });

  test('a successful unlock also lifts an active lock', () {
    for (var i = 0; i < 5; i++) {
      attempts.recordFailure();
    }
    attempts.recordSuccess();
    expect(attempts.isLocked(), isFalse);
  });

  test('the caller can set a stricter policy', () {
    final strict = PasscodeAttempts(
      maxFailures: 3,
      cooldown: const Duration(minutes: 1),
      now: () => now,
    );
    for (var i = 0; i < 3; i++) {
      strict.recordFailure();
    }
    expect(strict.isLocked(), isTrue);
    expect(strict.remainingSeconds(), 60);
  });
}
