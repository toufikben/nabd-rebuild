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

  group('persisted throttle', () {
    late _MemoryStore store;

    PasscodeAttempts reopen() =>
        PasscodeAttempts(store: store, now: () => now);

    setUp(() => store = _MemoryStore());

    test('killing the app does not hand out a fresh set of tries', () async {
      final first = reopen();
      for (var i = 0; i < 5; i++) {
        await first.recordFailure();
      }
      final second = reopen();
      await second.load();
      expect(second.isLocked(), isTrue);
      expect(second.remainingSeconds(), 30);
    });

    test('failures below the limit also survive a restart', () async {
      final first = reopen();
      for (var i = 0; i < 4; i++) {
        await first.recordFailure();
      }
      final second = reopen();
      await second.load();
      await second.recordFailure();
      expect(second.isLocked(), isTrue);
    });

    test('each lockout in a row doubles the wait', () async {
      final pad = reopen();
      for (var round = 0; round < 3; round++) {
        for (var i = 0; i < 5; i++) {
          await pad.recordFailure();
        }
        final expected = 30 * (1 << round);
        expect(pad.remainingSeconds(), expected);
        now = now.add(Duration(seconds: expected));
      }
    });

    test('the wait never exceeds the cap', () async {
      final pad = reopen();
      for (var round = 0; round < 12; round++) {
        for (var i = 0; i < 5; i++) {
          await pad.recordFailure();
        }
        expect(pad.remainingSeconds(), lessThanOrEqualTo(3600));
        now = now.add(Duration(seconds: pad.remainingSeconds()));
      }
    });

    test('a clock moved back cannot extend the lock past the cap', () async {
      final pad = reopen();
      for (var i = 0; i < 5; i++) {
        await pad.recordFailure();
      }
      now = now.subtract(const Duration(days: 30));
      final reopened = reopen();
      await reopened.load();
      expect(reopened.remainingSeconds(), lessThanOrEqualTo(3600));
    });

    test('a successful unlock clears the stored record', () async {
      final pad = reopen();
      for (var i = 0; i < 3; i++) {
        await pad.recordFailure();
      }
      await pad.recordSuccess();
      expect(store.values, isEmpty);
    });

    test('a corrupted record is ignored', () async {
      store.values[PasscodeAttempts.storageKey] = 'garbage';
      final pad = reopen();
      await pad.load();
      expect(pad.isLocked(), isFalse);
    });
  });
}

class _MemoryStore implements PasscodeStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
