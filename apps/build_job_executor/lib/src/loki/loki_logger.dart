import 'dart:convert';
import 'dart:io';

class LokiLogger {
  final String lokiUrl;
  final HttpClient _client;

  LokiLogger({
    required this.lokiUrl,
    HttpClient? client,
  }) : _client = client ?? HttpClient();

  Future<void> pushLog({
    required String runId,
    required String jobId,
    required String message,
    String stream = 'stdout',
    String type = 'step_log',
    String? stepId,
    String? command,
  }) async {
    final timestampNanos =
        (DateTime.now().toUtc().microsecondsSinceEpoch * 1000).toString();

    final labels = <String, String>{
      'stream': stream,
      'type': type,
      'run_id': runId,
      'build_job_id': jobId,
      if (stepId != null) 'step_id': stepId,
      if (command != null) 'command': command,
    };

    final payload = {
      'streams': [
        {
          'stream': labels,
          'values': [
            [timestampNanos, message],
          ],
        },
      ],
    };

    try {
      final uri = Uri.parse('$lokiUrl/loki/api/v1/push');
      final request = await _client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      await response.drain<void>();
    } catch (_) {
      // Best-effort: do not crash on log push failure
    }
  }

  Future<void> pushStepEvent({
    required String runId,
    required String jobId,
    required String stepId,
    required String name,
    required String status,
    required int stepOrder,
    int durationMs = 0,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final eventJson = jsonEncode({
      'id': stepId,
      'runId': runId,
      'name': name,
      'status': status,
      'durationMs': durationMs,
      'stepOrder': stepOrder,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    });

    await pushLog(
      runId: runId,
      jobId: jobId,
      message: eventJson,
      type: 'step_event',
      stepId: stepId,
    );
  }
}
