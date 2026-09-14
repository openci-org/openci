import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

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
  final chopperClient = ChopperClient(
    baseUrl: Uri.parse(lokiUrl),
    client: client,
    converter: const JsonConverter(),
  );
  final api = LokiApiService.create(chopperClient);
  final timestampNanos = (DateTime.now().toUtc().microsecondsSinceEpoch * 1000)
      .toString();
  final response = await api
      .push({
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
      })
      .whenComplete(chopperClient.dispose);
  // Loki acknowledges ingestion with 204; 260 means ingestion is blocked.
  if (response.statusCode != 204) {
    throw StateError(
      'Failed to push log to Loki: HTTP ${response.statusCode}.',
    );
  }
}
