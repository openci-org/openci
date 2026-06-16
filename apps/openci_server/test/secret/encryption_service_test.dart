import 'dart:convert';

import 'package:openci_server/secret/encryption_service.dart';
import 'package:test/test.dart';

void main() {
  group('EncryptionService Tests', () {
    // 32-byte Base64 key: [0, 1, ..., 31]
    const validKey = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=';
    // Another 32-byte Base64 key: [1, 2, ..., 32]
    const anotherKey = 'AQIDBAUGBwgJCgsMDQ4UEhMUFRYXGBkaGxwdHh8gISg=';

    test('Initialization succeeds with valid 32-byte Base64 key', () {
      expect(() => EncryptionService(validKey), returnsNormally);
    });

    test('Initialization throws on invalid key length', () {
      // 16-byte key: [0, 1, ..., 15]
      const invalidKey = 'AAECAwQFBgcICQoLDA0ODw==';
      expect(() => EncryptionService(invalidKey), throwsArgumentError);
    });

    test('Encrypt and decrypt returns original plain text', () async {
      final service = EncryptionService(validKey);
      const originalText = 'Hello, OpenCI Secret World! 🚀';

      final encrypted = await service.encrypt(originalText);
      expect(encrypted.split(':').length, equals(3));
      expect(encrypted, isNot(equals(originalText)));

      final decrypted = await service.decrypt(encrypted);
      expect(decrypted, equals(originalText));
    });

    test(
      'Encrypting same text twice results in different ciphertexts (due to random IV)',
      () async {
        final service = EncryptionService(validKey);
        const plainText = 'Stable text';

        final encrypted1 = await service.encrypt(plainText);
        final encrypted2 = await service.encrypt(plainText);

        expect(encrypted1, isNot(equals(encrypted2)));
        expect(await service.decrypt(encrypted1), equals(plainText));
        expect(await service.decrypt(encrypted2), equals(plainText));
      },
    );

    test('Decrypting with a different key fails', () async {
      final service1 = EncryptionService(validKey);
      final service2 = EncryptionService(anotherKey);
      const originalText = 'Secret Data';

      final encrypted = await service1.encrypt(originalText);

      expect(
        () => service2.decrypt(encrypted),
        throwsA(anything),
      );
    });

    test(
      'Tampering with ciphertext or MAC tag causes decryption to fail (AES-GCM integrity)',
      () async {
        final service = EncryptionService(validKey);
        const originalText = 'Authenticated Secret';
        final encrypted = await service.encrypt(originalText);

        final parts = encrypted.split(':');
        final iv = parts[0];
        final cipherText = parts[1];
        final mac = parts[2];

        // 1. Tamper ciphertext
        final tamperedCipherTextBytes = base64.decode(cipherText);
        tamperedCipherTextBytes[0] = tamperedCipherTextBytes[0] ^ 0xFF;
        final tamperedCipherText = base64.encode(tamperedCipherTextBytes);
        final tamperedEncrypted1 = '$iv:$tamperedCipherText:$mac';
        expect(() => service.decrypt(tamperedEncrypted1), throwsA(anything));

        // 2. Tamper MAC (authentication tag)
        final tamperedMacBytes = base64.decode(mac);
        tamperedMacBytes[0] = tamperedMacBytes[0] ^ 0xFF;
        final tamperedMac = base64.encode(tamperedMacBytes);
        final tamperedEncrypted2 = '$iv:$cipherText:$tamperedMac';
        expect(() => service.decrypt(tamperedEncrypted2), throwsA(anything));
      },
    );
  });
}
