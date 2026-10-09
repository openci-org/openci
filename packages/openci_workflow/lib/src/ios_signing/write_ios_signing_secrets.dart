import 'dart:convert';
import 'dart:io';

import '../app_store_connect_keys.dart';
import 'ios_signing_credentials.dart';

Future<IosSigningCredentials> writeIosSigningSecrets({
  required AppStoreConnectKeys ascKeys,
  required String certificatePrivateKey,
}) async {
  final List<int> ascPrivateKey;
  try {
    ascPrivateKey = base64Decode(ascKeys.privateKeyBase64);
  } on FormatException {
    throw const FormatException('Invalid Base64 content for ASC private key.');
  }

  final directory = Directory.fromUri(
    Directory.systemTemp.uri.resolve('openci-ios-signing/'),
  );
  await directory.create(recursive: true);
  await _setPermissions(directory.path, '700');

  final credentials = IosSigningCredentials(
    issuerId: ascKeys.issuerId,
    keyId: ascKeys.keyId,
    ascPrivateKeyPath: directory.uri.resolve('asc-private-key.p8').toFilePath(),
    certificatePrivateKeyPath: directory.uri
        .resolve('certificate-private-key.pem')
        .toFilePath(),
  );

  await _writePrivateKeyFile(
    path: credentials.ascPrivateKeyPath,
    bytes: ascPrivateKey,
  );
  await _writePrivateKeyFile(
    path: credentials.certificatePrivateKeyPath,
    bytes: utf8.encode(certificatePrivateKey.replaceAll(r'\n', '\n')),
  );

  return credentials;
}

Future<void> _writePrivateKeyFile({
  required String path,
  required List<int> bytes,
}) async {
  final file = File(path);
  await file.create();
  await _setPermissions(path, '600');
  await file.writeAsBytes(bytes, flush: true);
}

Future<void> _setPermissions(String path, String mode) async {
  final arguments = [mode, path];
  final result = await Process.run('chmod', arguments);
  if (result.exitCode != 0) {
    throw ProcessException(
      'chmod',
      arguments,
      'Could not set permissions for iOS signing secrets.',
      result.exitCode,
    );
  }
}
