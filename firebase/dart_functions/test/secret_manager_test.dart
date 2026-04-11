import 'dart:convert';

import 'package:dart_functions/secret_manager.dart';
import 'package:google_cloud_secretmanager_v1/secretmanager.dart';
import 'package:test/test.dart';

void main() {
  test('resolveProjectId throws when null', () {
    expect(() => resolveProjectId(null), throwsException);
  });

  test('resolveProjectId returns when not null', () {
    expect(resolveProjectId('test'), 'test');
  });

  test('buildSecretPath returns correct path', () {
    expect(
      buildSecretPath('test', 'secret'),
      'projects/test/secrets/secret/versions/latest',
    );
  });

  test('extractSecretData returns data', () {
    final response = AccessSecretVersionResponse(
      payload: SecretPayload(data: utf8.encode('my-secret-value')),
    );
    expect(extractSecretData(response, 'secret'), 'my-secret-value');
  });

  test('extractSecretData throws when no data', () {
    final response = AccessSecretVersionResponse();
    expect(() => extractSecretData(response, 'secret'), throwsException);
  });
}
