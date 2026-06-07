import 'dart:convert';
import 'package:googleapis/secretmanager/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

class GcpSecretManager {
  /// Fetches a secret string value from GCP Secret Manager using Application Default Credentials (ADC).
  ///
  /// The [pathToSecret] should be in the format:
  /// `projects/{projectId}/secrets/{secretName}`
  static Future<String> fetchSecretValue(String pathToSecret) async {
    final client = await clientViaApplicationDefaultCredentials(
      scopes: [
        SecretManagerApi.cloudPlatformScope,
      ],
    );

    try {
      final api = SecretManagerApi(client);
      final response = await api.projects.secrets.versions.access(
        '$pathToSecret/versions/latest',
      );
      final payload = response.payload?.data;

      if (payload == null || payload.isEmpty) {
        return '';
      }

      // Base64Url or Base64 decoding depending on payload format.
      // Usually standard Base64 padding is needed, standard base64 decoding supports both.
      final cleanPayload = payload
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();
      return utf8.decode(base64.decode(cleanPayload));
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
}
