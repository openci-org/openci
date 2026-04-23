import 'dart:convert';
import 'dart:io';

import 'package:google_cloud_secretmanager_v1/secretmanager.dart';
import 'package:googleapis_auth/auth_io.dart';

String resolveProjectId([String? override]) {
  final projectId = override ?? Platform.environment['GCLOUD_PROJECT'];
  if (projectId == null || projectId.trim().isEmpty) {
    throw Exception('GCLOUD_PROJECT environment variable is not set.');
  }
  return projectId;
}

String buildSecretPath(String projectId, String secretId) {
  if (secretId.trim().isEmpty) {
    throw Exception('secretId must not be empty.');
  }
  return 'projects/$projectId/secrets/$secretId/versions/latest';
}

String extractSecretData(
  AccessSecretVersionResponse response,
  String secretId,
) {
  final data = response.payload?.data;
  if (data == null) {
    throw Exception('Secret "$secretId" has no data.');
  }
  return utf8.decode(data);
}

Future<SecretManagerService> _createClient() async {
  final httpClient = await clientViaMetadataServer();
  return SecretManagerService(client: httpClient);
}

Future<String> accessSecret(String secretId) async {
  final projectId = resolveProjectId();
  final client = await _createClient();
  try {
    final response = await client.accessSecretVersion(
      AccessSecretVersionRequest(name: buildSecretPath(projectId, secretId)),
    );
    return extractSecretData(response, secretId);
  } finally {
    client.close();
  }
}

Future<String> createSecretWithValue(String secretId, String value) async {
  final projectId = resolveProjectId();
  final parent = 'projects/$projectId';
  final client = await _createClient();
  try {
    await client.createSecret(
      CreateSecretRequest(
        parent: parent,
        secretId: secretId,
        secret: Secret(
          replication: Replication(automatic: Replication_Automatic()),
        ),
      ),
    );

    await client.addSecretVersion(
      AddSecretVersionRequest(
        parent: '$parent/secrets/$secretId',
        payload: SecretPayload(data: utf8.encode(value)),
      ),
    );

    return '$parent/secrets/$secretId';
  } finally {
    client.close();
  }
}

Future<void> addSecretVersionByPath(String secretPath, String value) async {
  final client = await _createClient();
  try {
    await client.addSecretVersion(
      AddSecretVersionRequest(
        parent: secretPath,
        payload: SecretPayload(data: utf8.encode(value)),
      ),
    );
  } finally {
    client.close();
  }
}

Future<void> deleteSecretByPath(String secretPath) async {
  final client = await _createClient();
  try {
    await client.deleteSecret(DeleteSecretRequest(name: secretPath));
  } finally {
    client.close();
  }
}
