import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'cloud_function_caller.dart';

Future<void> sendHeartbeat({
  required ApiClient apiClient,
  required String workerId,
  required String version,
  required String status,
}) async {
  final serverUrl = apiClient.serverUrl;
  if (serverUrl == null || serverUrl.isEmpty) {
    throw StateError(
      'OPENCI_SERVER_URL must be configured to update worker heartbeat.',
    );
  }

  final url = Uri.parse('$serverUrl/workers/heartbeat');
  final idToken = await apiClient.authManager.getIdToken();
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({
      'workerId': workerId,
      'version': version,
      'platform': Platform.operatingSystem,
      'status': status,
    }),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Failed to update worker heartbeat on server: ${response.statusCode} ${response.body}',
    );
  }
}
