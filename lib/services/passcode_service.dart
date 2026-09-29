import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'encryption_service.dart';

/// Storage for the app passcode, kept behind an interface so the policy can be
/// tested without a platform channel.
abstract class PasscodeStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// The real store: the OS keystore, the same place the encryption master key
/// lives.
class SecureStoragePasscodeStore implements PasscodeStore {
  const SecureStoragePasscodeStore();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Thrown when a pin cannot be used at all (wrong length or non-digits).
class PasscodeFormatException implements Exception {
  const PasscodeFormatException(this.message);

  final String message;

  @override
  String toString() => 'PasscodeFormatException: $message';
}

typedef PasscodeKeyDeriver = Future<Uint8List> Function(
    String pin, Uint8List salt);

/// Stores and checks the numeric app passcode.
///
/// The pin itself is never kept: a random salt and the PBKDF2 digest of
/// `pin + salt` are, so a dump of storage cannot be read back as a number.
class PasscodeService {
  PasscodeService({
    required PasscodeStore store,
    required PasscodeKeyDeriver deriveKey,
    Uint8List Function(int length)? saltGenerator,
  })  : _store = store,
        _deriveKey = deriveKey,
        _saltGenerator = saltGenerator ?? _generateSalt;

  /// The service the app uses: the OS keystore and the real PBKDF2.
  factory PasscodeService.secure() {
    final encryption = EncryptionService();
    return PasscodeService(
      store: const SecureStoragePasscodeStore(),
      deriveKey: (pin, salt) async {
        final key = await encryption.deriveKeyFromPassword(
          password: pin,
          salt: salt,
        );
        return Uint8List.fromList(await key.extractBytes());
      },
    );
  }

  static const saltKey = 'nabd_passcode_salt';
  static const hashKey = 'nabd_passcode_hash';
  static const minLength = 4;
  static const maxLength = 6;
  static const _saltLength = 16;

  static final RegExp _digits = RegExp(r'^[0-9]+$');

  final PasscodeStore _store;
  final PasscodeKeyDeriver _deriveKey;
  final Uint8List Function(int length) _saltGenerator;

  static bool isValidFormat(String pin) {
    return pin.length >= minLength &&
        pin.length <= maxLength &&
        _digits.hasMatch(pin);
  }

  Future<void> setPasscode(String pin) async {
    if (!isValidFormat(pin)) {
      throw const PasscodeFormatException('Passcode must be 4 to 6 digits');
    }
    final salt = _saltGenerator(_saltLength);
    final hash = await _deriveKey(pin, salt);
    await _store.write(saltKey, base64Encode(salt));
    await _store.write(hashKey, base64Encode(hash));
  }

  Future<bool> verify(String pin) async {
    if (!isValidFormat(pin)) return false;
    final storedSalt = await _store.read(saltKey);
    final storedHash = await _store.read(hashKey);
    if (storedSalt == null || storedHash == null) return false;

    final expected = base64Decode(storedHash);
    final actual = await _deriveKey(pin, base64Decode(storedSalt));
    return _matches(expected, actual);
  }

  Future<bool> hasPasscode() async {
    final salt = await _store.read(saltKey);
    final hash = await _store.read(hashKey);
    return salt != null && hash != null;
  }

  Future<void> removePasscode() async {
    await _store.delete(saltKey);
    await _store.delete(hashKey);
  }
}

Uint8List _generateSalt(int length) =>
    EncryptionService().generateSalt(length);

/// Compares two digests without leaking how far apart they are through timing.
bool _matches(List<int> expected, List<int> actual) {
  if (expected.length != actual.length) return false;
  var difference = 0;
  for (var i = 0; i < expected.length; i++) {
    difference |= expected[i] ^ actual[i];
  }
  return difference == 0;
}

/// Counts failed unlock attempts and locks the pad for a cooldown, so a stolen
/// phone cannot be picked by trying every four-digit combination.
class PasscodeAttempts {
  PasscodeAttempts({
    this.maxFailures = 5,
    this.cooldown = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int maxFailures;
  final Duration cooldown;
  final DateTime Function() _now;

  int _failures = 0;
  DateTime? _lockedUntil;

  int get failures {
    _settle();
    return _failures;
  }

  bool isLocked() {
    _settle();
    return _lockedUntil != null;
  }

  int remainingSeconds() {
    final lockedUntil = _lockedUntil;
    if (lockedUntil == null) return 0;
    final remaining = lockedUntil.difference(_now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void recordFailure() {
    _settle();
    if (_lockedUntil != null) return;
    _failures += 1;
    if (_failures >= maxFailures) {
      _lockedUntil = _now().add(cooldown);
    }
  }

  void recordSuccess() {
    _failures = 0;
    _lockedUntil = null;
  }

  /// An expired lock is over: the user gets a full set of tries again.
  void _settle() {
    final lockedUntil = _lockedUntil;
    if (lockedUntil != null && !_now().isBefore(lockedUntil)) {
      _lockedUntil = null;
      _failures = 0;
    }
  }
}
