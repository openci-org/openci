import 'dart:convert';

import 'package:http/http.dart' as http;

/// Sends one log entry. The caller owns [client] and handles delivery failures.
Future<void> pushLogToLoki({
  required http.Client client,
  required String lokiUrl,
  required String runId,
  required String jobId,
  required String message,
  String stream = 'stdout',
  String type = 'step_log',
  String? stepId,
  String? command,
}) async {
  final baseUri = Uri.parse(lokiUrl);
  final uri = baseUri.replace(
    pathSegments: [
      ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
      'loki',
      'api',
      'v1',
      'push',
    ],
  );
  final timestampNanos = (DateTime.now().toUtc().microsecondsSinceEpoch * 1000)
      .toString();
  final response = await client.post(
    uri,
    headers: {'Content-Type': 'application/json; charset=utf-8'},
    body: jsonEncode({
      'streams': [
        {
          'stream': {
            'stream': stream,
            'type': type,
            'run_id': runId,
            'build_job_id': jobId,
            'step_id': ?stepId,
            'command': ?command,
          },
          'values': [
            [timestampNanos, message],
          ],
        },
      ],
    }),
  );
  // Loki acknowledges ingestion with 204; 260 means ingestion is blocked.
  if (response.statusCode != 204) {
    throw StateError(
      'Failed to push log to Loki: HTTP ${response.statusCode}.',
    );
  }
}
