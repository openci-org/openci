import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'asc_api_key.dart';

const ascApiKeySecretName = 'ASC_API_KEY';

/// Loads a previously issued key without contacting Apple or issuing another.
Future<AscApiKey> readSavedAscApiKey(Directory directory) async {
  final metadata = File(p.join(directory.absolute.path, 'key.json'));
  final json = jsonDecode(await _readKeyFile(metadata));
  if (json is! Map<String, dynamic>) {
    throw const FormatException('Invalid key metadata.');
  }
  final keyId = json['keyId'];
  final issuerId = json['issuerId'];
  final savedPath = json['p8Path'];
  if (keyId is! String ||
      !RegExp(r'^[A-Za-z0-9]+$').hasMatch(keyId) ||
      issuerId is! String ||
      issuerId.trim().isEmpty ||
      RegExp(r'[\x00-\x1f\x7f-\x9f]').hasMatch(issuerId) ||
      savedPath is! String ||
      json['role'] != 'APP_MANAGER') {
    throw const FormatException('Invalid key metadata.');
  }
  final keyFile = File(p.join(directory.absolute.path, 'AuthKey_$keyId.p8'));
  if (!p.equals(p.normalize(savedPath), p.normalize(keyFile.path))) {
    throw const FormatException('The private key must be in this directory.');
  }
  final key = AscApiKey(
    keyId: keyId,
    issuerId: issuerId.trim(),
    privateKeyFile: keyFile,
  );
  await encodeAscApiKeySecret(key);
  return key;
}

/// Encodes the three credentials in fastlane's API key JSON format.
Future<String> encodeAscApiKeySecret(AscApiKey key) async {
  final pem = await _readKeyFile(key.privateKeyFile);
  final match = RegExp(
    r'^-----BEGIN PRIVATE KEY-----\r?\n([A-Za-z0-9+/=\r\n]+)\r?\n-----END PRIVATE KEY-----\s*$',
  ).firstMatch(pem);
  if (match == null ||
      base64Decode(match[1]!.replaceAll(RegExp(r'\s'), '')).isEmpty) {
    throw const FormatException('Invalid private key file.');
  }
  return jsonEncode({
    'key_id': key.keyId,
    'issuer_id': key.issuerId,
    'key': pem,
  });
}

Future<String> _readKeyFile(File file) async {
  if (await FileSystemEntity.type(file.path, followLinks: false) !=
          FileSystemEntityType.file ||
      await file.length() > 16 * 1024) {
    throw const FormatException('Invalid key file.');
  }
  final bytes = <int>[];
  await for (final chunk in file.openRead()) {
    if (bytes.length + chunk.length > 16 * 1024) {
      throw const FormatException('Key file is too large.');
    }
    bytes.addAll(chunk);
  }
  return utf8.decode(bytes);
}
