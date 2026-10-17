import 'dart:convert';

import 'package:openci_server/github/decrypt_github_connection_token.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, String> environment;
  late String encryptedToken;

  setUp(() async {
    final key = base64Encode(List<int>.filled(32, 1));
    environment = {'SECRET_ENCRYPTION_KEY': key};
    encryptedToken = await SecretCrypter(key).encrypt('private-github-token');
  });

  final sanitizedFailure = throwsA(
    isA<StateError>().having(
      (error) => error.message,
      'safe error message',
      'Failed to decrypt GitHub connection token',
    ),
  );

  test('decrypts the token using the configured key', () async {
    final token = await decryptGitHubConnectionToken(
      encryptedToken,
      environment,
    );

    expect(token, 'private-github-token');
  });

  test('reports a missing encryption key with a sanitized error', () async {
    environment.clear();

    await expectLater(
      decryptGitHubConnectionToken(encryptedToken, environment),
      sanitizedFailure,
    );
  });

  test('does not expose an invalid encryption key in the error', () async {
    environment['SECRET_ENCRYPTION_KEY'] = 'private-invalid-key';

    await expectLater(
      decryptGitHubConnectionToken(encryptedToken, environment),
      sanitizedFailure,
    );
  });

  test('does not expose malformed ciphertext in the error', () async {
    await expectLater(
      decryptGitHubConnectionToken('private-invalid-ciphertext', environment),
      sanitizedFailure,
    );
  });

  test(
    'sanitizes asynchronous decryption failure with a different key',
    () async {
      environment['SECRET_ENCRYPTION_KEY'] = base64Encode(
        List<int>.filled(32, 2),
      );

      await expectLater(
        decryptGitHubConnectionToken(encryptedToken, environment),
        sanitizedFailure,
      );
    },
  );
}
