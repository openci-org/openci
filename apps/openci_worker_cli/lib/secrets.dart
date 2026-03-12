import 'dart:convert';
import 'dart:io';

import 'package:googleapis/secretmanager/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

Future<String> fetchSecretValue(
  String projectId,
  String pathToSecret,
  String serviceAccountPath,
) async {
  final credentials = ServiceAccountCredentials.fromJson(
    File(serviceAccountPath).readAsStringSync(),
  );

  final client = await clientViaServiceAccount(credentials, [
    SecretManagerApi.cloudPlatformScope,
  ]);

  try {
    final api = SecretManagerApi(client);
    final response = await api.projects.secrets.versions.access(
      '$pathToSecret/versions/latest',
    );
    final payload = response.payload?.data;

    if (payload == null || payload.isEmpty) {
      return '';
    }

    return utf8.decode(base64.decode(payload));
  } catch (e) {
    if (e.toString().contains('NOT_FOUND') ||
        e.toString().contains('404') ||
        e.toString().contains('no versions')) {
      return '';
    }
    rethrow;
  } finally {
    client.close();
  }
}
