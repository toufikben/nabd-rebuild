import 'dart:typed_data';

/// Storage for the app passcode. Kept behind an interface so the policy can be
/// tested without a platform channel.
abstract class PasscodeStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Thrown when a pin cannot be used at all (wrong length or non-digits).
class PasscodeFormatException implements Exception {
  const PasscodeFormatException(this.message);

  final String message;
}

typedef PasscodeKeyDeriver = Future<Uint8List> Function(
    String pin, Uint8List salt);

/// Stores and checks the numeric app passcode.
class PasscodeService {
  PasscodeService({
    required PasscodeStore store,
    required PasscodeKeyDeriver deriveKey,
    Uint8List Function(int length)? saltGenerator,
  });

  static const saltKey = 'nabd_passcode_salt';
  static const hashKey = 'nabd_passcode_hash';

  static bool isValidFormat(String pin) {
    throw UnimplementedError();
  }

  Future<void> setPasscode(String pin) async {
    throw UnimplementedError();
  }

  Future<bool> verify(String pin) async {
    throw UnimplementedError();
  }

  Future<bool> hasPasscode() async {
    throw UnimplementedError();
  }

  Future<void> removePasscode() async {
    throw UnimplementedError();
  }
}

/// Counts failed unlock attempts and locks the pad for a cooldown.
class PasscodeAttempts {
  PasscodeAttempts({
    int maxFailures = 5,
    Duration cooldown = const Duration(seconds: 30),
    DateTime Function()? now,
  });

  int get failures => throw UnimplementedError();

  bool isLocked() => throw UnimplementedError();

  int remainingSeconds() => throw UnimplementedError();

  void recordFailure() => throw UnimplementedError();

  void recordSuccess() => throw UnimplementedError();
}
