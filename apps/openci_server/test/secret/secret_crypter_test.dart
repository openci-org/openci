import 'dart:convert';

import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

void main() {
  const validKey = 'A9hs566HtB6B0ZEB2aKkAZpC81VGQxKMlFspt+vA5F4=';
  const invalidKey = 'too_short_key_base64';

  group('SecretCrypter', () {
    test('Constructor throws ArgumentError for invalid key size', () {
      expect(() => SecretCrypter(invalidKey), throwsArgumentError);
    });

    test('Encrypt and decrypt a simple string', () async {
      final crypter = SecretCrypter(validKey);
      const plaintext = 'hello world';

      final ciphertext = await crypter.encrypt(plaintext);
      expect(ciphertext, isNot(equals(plaintext)));

      final decrypted = await crypter.decrypt(ciphertext);
      expect(decrypted, equals(plaintext));
    });

    test('Encrypt and decrypt empty and long Unicode strings', () async {
      final crypter = SecretCrypter(validKey);

      for (final plaintext in [
        '',
        'こんにちは、世界！',
        'A' * 1000,
      ]) {
        final ciphertext = await crypter.encrypt(plaintext);
        final decrypted = await crypter.decrypt(ciphertext);
        expect(decrypted, equals(plaintext));
      }
    });

    test('Encryption output is different each time (Random IV)', () async {
      final crypter = SecretCrypter(validKey);
      const plaintext = 'same plaintext';

      final ciphertext1 = await crypter.encrypt(plaintext);
      final ciphertext2 = await crypter.encrypt(plaintext);

      expect(ciphertext1, isNot(equals(ciphertext2)));
      expect(await crypter.decrypt(ciphertext1), equals(plaintext));
      expect(await crypter.decrypt(ciphertext2), equals(plaintext));
    });

    test('Decrypt throws Exception for corrupted ciphertext', () async {
      final crypter = SecretCrypter(validKey);

      expect(
        crypter.decrypt(base64.encode([1, 2, 3])),
        throwsA(anything),
      );

      final ciphertext = await crypter.encrypt('test');
      final bytes = base64.decode(ciphertext);
      bytes[bytes.length - 1] ^= 0xFF;
      final corrupted = base64.encode(bytes);

      expect(
        crypter.decrypt(corrupted),
        throwsA(anything),
      );
    });
  });
}
