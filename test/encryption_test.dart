import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AES-256-GCM Encryption', () {
    final algorithm = AesGcm.with256bits();

    test('encrypts and decrypts successfully', () async {
      final key = await algorithm.newSecretKey();
      final plaintext = 'مذكرة سرية اليوم 😊';

      // Encrypt
      final nonce = algorithm.newNonce();
      final secretBox = await algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
        nonce: nonce,
      );

      // Combine
      final combined = Uint8List.fromList([
        ...secretBox.nonce,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ]);

      // Decrypt
      const nonceLen = 12;
      const macLen = 16;
      final extractedNonce = combined.sublist(0, nonceLen);
      final cipherText = combined.sublist(nonceLen, combined.length - macLen);
      final macBytes = combined.sublist(combined.length - macLen);

      final restoredBox = SecretBox(
        cipherText,
        nonce: extractedNonce,
        mac: Mac(macBytes),
      );

      final decrypted = await algorithm.decrypt(restoredBox, secretKey: key);
      expect(utf8.decode(decrypted), plaintext);
    });

    test('fails with wrong key', () async {
      final key1 = await algorithm.newSecretKey();
      final key2 = await algorithm.newSecretKey();
      final plaintext = 'secret';

      final nonce = algorithm.newNonce();
      final secretBox = await algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: key1,
        nonce: nonce,
      );

      expect(
        () => algorithm.decrypt(secretBox, secretKey: key2),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('fails with tampered ciphertext', () async {
      final key = await algorithm.newSecretKey();
      final plaintext = 'important data';

      final nonce = algorithm.newNonce();
      final secretBox = await algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
        nonce: nonce,
      );

      // Tamper: change one byte of ciphertext
      final tampered = Uint8List.fromList(secretBox.cipherText);
      tampered[0] = (tampered[0] + 1) & 0xFF;

      final tamperedBox = SecretBox(
        tampered,
        nonce: secretBox.nonce,
        mac: secretBox.mac,
      );

      expect(
        () => algorithm.decrypt(tamperedBox, secretKey: key),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('fails with tampered MAC', () async {
      final key = await algorithm.newSecretKey();
      final plaintext = 'important data';

      final nonce = algorithm.newNonce();
      final secretBox = await algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
        nonce: nonce,
      );

      // Tamper MAC
      final tamperedMac = Uint8List.fromList(secretBox.mac.bytes);
      tamperedMac[0] = (tamperedMac[0] + 1) & 0xFF;

      final tamperedBox = SecretBox(
        secretBox.cipherText,
        nonce: secretBox.nonce,
        mac: Mac(tamperedMac),
      );

      expect(
        () => algorithm.decrypt(tamperedBox, secretKey: key),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('handles empty plaintext', () async {
      final key = await algorithm.newSecretKey();
      final nonce = algorithm.newNonce();

      final secretBox = await algorithm.encrypt(
        <int>[],
        secretKey: key,
        nonce: nonce,
      );

      final decrypted = await algorithm.decrypt(secretBox, secretKey: key);
      expect(decrypted, isEmpty);
    });

    test('handles Arabic + emoji text', () async {
      final key = await algorithm.newSecretKey();
      final plaintext = 'سعيد 🎉 جداً ❤️ اليوم';

      final nonce = algorithm.newNonce();
      final secretBox = await algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
        nonce: nonce,
      );

      final decrypted = await algorithm.decrypt(secretBox, secretKey: key);
      expect(utf8.decode(decrypted), plaintext);
    });
  });

  group('PBKDF2 Key Derivation', () {
    test('derives same key for same password + salt', () async {
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 10000,
        bits: 256,
      );

      final salt = Uint8List.fromList(List.generate(16, (i) => i));

      final key1 = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode('my-password')),
        nonce: salt,
      );
      final key2 = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode('my-password')),
        nonce: salt,
      );

      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();

      expect(bytes1, equals(bytes2));
    });

    test('derives different keys for different passwords', () async {
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 10000,
        bits: 256,
      );

      final salt = Uint8List.fromList(List.generate(16, (i) => i));

      final key1 = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode('password-1')),
        nonce: salt,
      );
      final key2 = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode('password-2')),
        nonce: salt,
      );

      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();

      expect(bytes1, isNot(equals(bytes2)));
    });
  });
}
