import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/encryption_service.dart';
import 'package:nabd/services/passcode_service.dart';

/// An in-memory stand-in for the secure storage so the tests never touch a
/// platform channel, and so they can read back exactly what was written.
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

/// Stands in for PBKDF2: deterministic and instant, but one-way like the real
/// thing, so the "the pin is never stored readably" assertion stays meaningful.
Future<Uint8List> _derive(String pin, Uint8List salt) async {
  return Hmac(sha256, salt).convert(utf8.encode(pin)).bytes;
}

void main() {
  late _MemoryStore store;
  late PasscodeService service;

  setUp(() {
    store = _MemoryStore();
    service = PasscodeService(
      store: store,
      deriveKey: _derive,
      saltGenerator: (length) => Uint8List.fromList(List<int>.filled(length, 7)),
    );
  });

  group('format', () {
    test('accepts four to six digits', () {
      expect(PasscodeService.isValidFormat('1234'), isTrue);
      expect(PasscodeService.isValidFormat('123456'), isTrue);
    });

    test('rejects too short, too long, and non-digits', () {
      expect(PasscodeService.isValidFormat('123'), isFalse);
      expect(PasscodeService.isValidFormat('1234567'), isFalse);
      expect(PasscodeService.isValidFormat('12a4'), isFalse);
      expect(PasscodeService.isValidFormat(''), isFalse);
      expect(PasscodeService.isValidFormat('12 34'), isFalse);
    });
  });

  group('setPasscode', () {
    test('refuses an invalid pin and stores nothing', () async {
      await expectLater(
        service.setPasscode('12'),
        throwsA(isA<PasscodeFormatException>()),
      );
      expect(store.values, isEmpty);
      expect(await service.hasPasscode(), isFalse);
    });

    test('reports the passcode as absent before one is set', () async {
      expect(await service.hasPasscode(), isFalse);
    });

    test('reports the passcode as present after it is set', () async {
      await service.setPasscode('4789');
      expect(await service.hasPasscode(), isTrue);
    });

    test('never stores the pin where it can be read back', () async {
      await service.setPasscode('4789');

      for (final entry in store.values.entries) {
        expect(entry.value.contains('4789'), isFalse, reason: entry.key);
        final decoded = utf8.decode(base64Decode(entry.value), allowMalformed: true);
        expect(decoded.contains('4789'), isFalse, reason: entry.key);
      }
    });
  });

  group('verify', () {
    test('accepts the pin that was set', () async {
      await service.setPasscode('4789');
      expect(await service.verify('4789'), isTrue);
    });

    test('rejects a different pin', () async {
      await service.setPasscode('4789');
      expect(await service.verify('9874'), isFalse);
    });

    test('rejects anything when no pin is stored', () async {
      expect(await service.verify('4789'), isFalse);
    });

    test('rejects an invalid pin without reading storage', () async {
      await service.setPasscode('4789');
      expect(await service.verify('47'), isFalse);
    });

    test('the real derivation accepts the same pin twice', () async {
      final secure = PasscodeService(
        store: store,
        deriveKey: (pin, salt) async {
          final key = await EncryptionService()
              .deriveKeyFromPassword(password: pin, salt: salt);
          return Uint8List.fromList(await key.extractBytes());
        },
      );
      await secure.setPasscode('2468');
      expect(await secure.verify('2468'), isTrue);
      expect(await secure.verify('8642'), isFalse);
    });
  });

  group('change and remove', () {
    test('setting a new pin invalidates the old one', () async {
      await service.setPasscode('4789');
      await service.setPasscode('1357');
      expect(await service.verify('4789'), isFalse);
      expect(await service.verify('1357'), isTrue);
    });

    test('two identical pins produce different stored records', () async {
      final real = PasscodeService(
        store: store,
        deriveKey: _derive,
      );
      await real.setPasscode('4747');
      final first = Map<String, String>.from(store.values);
      await real.setPasscode('4747');
      expect(store.values[PasscodeService.saltKey],
          isNot(first[PasscodeService.saltKey]));
      expect(store.values[PasscodeService.hashKey],
          isNot(first[PasscodeService.hashKey]));
    });

    test('removePasscode clears the records and later verifies fail', () async {
      await service.setPasscode('4789');
      await service.removePasscode();
      expect(store.values, isEmpty);
      expect(await service.hasPasscode(), isFalse);
      expect(await service.verify('4789'), isFalse);
    });

    test('removing twice is not an error', () async {
      await service.setPasscode('4789');
      await service.removePasscode();
      await service.removePasscode();
      expect(await service.hasPasscode(), isFalse);
    });

    test('a record written by another feature is not read', () async {
      await service.setPasscode('4789');
      store.values['nabd_backup_key'] = 'unrelated';
      expect(await service.verify('4789'), isTrue);
      expect(store.values.containsKey(PasscodeService.saltKey), isTrue);
    });
  });
}
