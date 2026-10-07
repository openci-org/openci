import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'asc_api_key.dart';

const ascKeyIdSecretName = 'OPENCI_GENERATED_ASC_KEY_ID';
const ascIssuerIdSecretName = 'OPENCI_GENERATED_ASC_ISSUER_ID';
const ascP8SecretName = 'OPENCI_GENERATED_P8_BASE64';
const ascApiKeySecretNames = [
  ascKeyIdSecretName,
  ascIssuerIdSecretName,
  ascP8SecretName,
];

/// Loads a previously issued key without contacting Apple or issuing another.
Future<AscApiKey> readSavedAscApiKey(Directory directory) async {
  final metadata = File(p.join(directory.absolute.path, 'key.json'));
  final json = jsonDecode(utf8.decode(await _readKeyFile(metadata)));
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
  await encodeAscApiKeySecrets(key);
  return key;
}

/// Prepares two text secrets and a Base64-encoded private-key file secret.
Future<Map<String, String>> encodeAscApiKeySecrets(AscApiKey key) async {
  final bytes = await _readKeyFile(key.privateKeyFile);
  final pem = utf8.decode(bytes);
  final match = RegExp(
    r'^-----BEGIN PRIVATE KEY-----\r?\n([A-Za-z0-9+/=\r\n]+)\r?\n-----END PRIVATE KEY-----\s*$',
  ).firstMatch(pem);
  if (match == null ||
      base64Decode(match[1]!.replaceAll(RegExp(r'\s'), '')).isEmpty) {
    throw const FormatException('Invalid private key file.');
  }
  return {
    ascKeyIdSecretName: key.keyId,
    ascIssuerIdSecretName: key.issuerId,
    ascP8SecretName: base64Encode(bytes),
  };
}

Future<List<int>> _readKeyFile(File file) async {
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
  return bytes;
}
