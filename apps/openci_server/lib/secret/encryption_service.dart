import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:openci_server/environment_value/environment_value.dart';
import 'package:riverpod/riverpod.dart';

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  final env = ref.watch(environmentValueProvider);
  final key = env.secretEncryptionKey;
  if (key.trim().isEmpty) {
    throw StateError('SECRET_ENCRYPTION_KEY is missing or empty.');
  }
  return EncryptionService(key);
});

class EncryptionService {
  final SecretKey _secretKey;
  final AesCbc _algorithm;

  EncryptionService(String base64Key)
    : _secretKey = SecretKey(base64.decode(base64Key.trim())),
      _algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty) {
    final keyBytes = base64.decode(base64Key.trim());
    if (keyBytes.length != 32) {
      throw ArgumentError(
        'SECRET_ENCRYPTION_KEY must be a 32-byte Base64 encoded string. Got ${keyBytes.length} bytes.',
      );
    }
  }

  Future<String> encrypt(String plainText) async {
    final plainBytes = utf8.encode(plainText);

    final secretBox = await _algorithm.encrypt(
      plainBytes,
      secretKey: _secretKey,
    );

    final ivBase64 = base64.encode(secretBox.nonce);
    final cipherTextBase64 = base64.encode(secretBox.cipherText);

    return '$ivBase64:$cipherTextBase64';
  }

  Future<String> decrypt(String encryptedString) async {
    final parts = encryptedString.split(':');
    if (parts.length != 2) {
      throw ArgumentError(
        'Invalid encrypted format. Expected "iv:ciphertext".',
      );
    }

    final iv = base64.decode(parts[0]);
    final cipherText = base64.decode(parts[1]);

    final secretBox = SecretBox(
      cipherText,
      nonce: iv,
      mac: Mac.empty,
    );

    final clearBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: _secretKey,
    );

    return utf8.decode(clearBytes);
  }
}
