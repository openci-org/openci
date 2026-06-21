import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class SecretCrypter {
  final List<int> _keyBytes;
  final _algorithm = AesGcm.with256bits();

  SecretCrypter(String base64Key) : _keyBytes = base64.decode(base64Key) {
    if (_keyBytes.length != 32) {
      throw ArgumentError(
        'Encryption key must be exactly 32 bytes (256 bits) after base64 decoding.',
      );
    }
  }

  Future<String> encrypt(String plainText) async {
    final secretKey = SecretKey(_keyBytes);
    final secretBox = await _algorithm.encryptString(
      plainText,
      secretKey: secretKey,
    );
    return base64.encode(secretBox.concatenation());
  }

  Future<String> decrypt(String base64Ciphertext) async {
    final secretKey = SecretKey(_keyBytes);
    final bytes = base64.decode(base64Ciphertext);

    final secretBox = SecretBox.fromConcatenation(
      bytes,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );

    return _algorithm.decryptString(secretBox, secretKey: secretKey);
  }
}
