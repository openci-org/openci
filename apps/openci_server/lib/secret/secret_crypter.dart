import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class SecretCrypter {
  final List<int> _keyBytes;
  final _algorithm = AesGcm.with256bits();

  SecretCrypter(String base64Key) : _keyBytes = _decodeKey(base64Key);

  static List<int> _decodeKey(String base64Key) {
    try {
      final decoded = base64.decode(base64Key);
      if (decoded.length != 32) {
        throw ArgumentError(
          'Encryption key must be exactly 32 bytes (256 bits) after base64 decoding.',
        );
      }
      return decoded;
    } on FormatException catch (e) {
      throw ArgumentError(
        'Invalid base64 format for encryption key: $e',
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
