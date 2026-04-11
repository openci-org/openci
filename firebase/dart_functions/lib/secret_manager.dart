import 'dart:convert';
import 'dart:io';

import 'package:google_cloud_secretmanager_v1/secretmanager.dart';
import 'package:googleapis_auth/auth_io.dart';

String resolveProjectId([String? override]) {
  final projectId = override ?? Platform.environment['GCLOUD_PROJECT'];
  if (projectId == null) {
    throw Exception('GCLOUD_PROJECT environment variable is not set.');
  }
  return projectId;
}

String buildSecretPath(String projectId, String secretId) =>
    'projects/$projectId/secrets/$secretId/versions/latest';

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

Future<String> accessSecret(String secretId) async {
  final projectId = resolveProjectId();
  final httpClient = await clientViaMetadataServer();
  final client = SecretManagerService(client: httpClient);
  try {
    final response = await client.accessSecretVersion(
      AccessSecretVersionRequest(name: buildSecretPath(projectId, secretId)),
    );
    return extractSecretData(response, secretId);
  } finally {
    client.close();
  }
}
