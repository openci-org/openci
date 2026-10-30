import 'dart:io';

import 'package:meta/meta.dart';
import 'secrets_api.dart';

Future<List<String>> fetchSecretNames(SecretsApi api, String teamId) async {
  final response = await api.getSecrets(teamId);
  if (response.statusCode != HttpStatus.ok) {
    throw SecretNamesHttpException(response.statusCode);
  }
  return parseSecretNamesResponse(response.body);
}

@visibleForTesting
List<String> parseSecretNamesResponse(Map<String, dynamic>? body) {
  if (body == null || body['success'] != true || body['secrets'] is! List) {
    throw const FormatException('Invalid secrets response');
  }
  return (body['secrets'] as List).map((secret) {
    if (secret is! Map<String, dynamic> || secret['name'] is! String) {
      throw const FormatException('Invalid secrets response');
    }
    return secret['name'] as String;
  }).toList();
}

class SecretNamesHttpException implements Exception {
  const SecretNamesHttpException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Failed to fetch secret names (HTTP $statusCode).';
}
