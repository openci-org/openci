import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart' as dart_logging;
import 'package:openci_build_job_processor/src/logging/loki_api_service.dart';

final _log = dart_logging.Logger('BuildStepLog');

String? _lokiUrl;
String? _serverUrl;
String? _internalApiKey;
LokiApiService? _lokiApiService;

void setupBuildStepLogger({
  String? serverUrl,
  String? internalApiKey,
  String? lokiUrl,
}) {
  _serverUrl = serverUrl;
  _internalApiKey = internalApiKey;
  _lokiUrl =
      lokiUrl ?? Platform.environment['LOKI_URL'] ?? 'http://localhost:3100';

  final chopperClient = ChopperClient(
    baseUrl: Uri.parse(_lokiUrl!),
    services: [LokiApiService.create()],
    converter: const JsonConverter(),
  );
  _lokiApiService = chopperClient.getService<LokiApiService>();
}

LokiApiService _getLokiService() {
  if (_lokiApiService != null) return _lokiApiService!;
  final baseUrl =
      _lokiUrl ?? Platform.environment['LOKI_URL'] ?? 'http://localhost:3100';
  final chopperClient = ChopperClient(
    baseUrl: Uri.parse(baseUrl),
    services: [LokiApiService.create()],
    converter: const JsonConverter(),
  );
  _lokiApiService = chopperClient.getService<LokiApiService>();
  return _lokiApiService!;
}

/// ログ発生時にダイレクトに Loki へ Chopper 経由で Push 送信 (Direct Push)
Future<void> writeBuildStepLog(
  String buildJobId,
  String runId,
  String stepId,
  String message,
) async {
  if (message.isEmpty) return;

  final payload = createLokiPayload(
    labels: {'build_job_id': buildJobId, 'run_id': runId, 'step_id': stepId},
    message: message,
  );

  try {
    final response = await _getLokiService().pushLogs(payload);

    if (!response.isSuccessful) {
      _log.warning('Failed to push log to Loki: HTTP ${response.statusCode}');
    }
  } catch (e) {
    _log.warning('Error pushing log to Loki: $e');
  }
}

Future<void> sendStepStatusUpdate({
  required String buildJobId,
  required String runId,
  required String stepId,
  required String name,
  required String status,
  required int durationMs,
  required int stepOrder,
  required String createdAt,
  required String updatedAt,
}) async {
  final baseServerUrl = _serverUrl ?? 'http://localhost:8080';
  final url = Uri.parse('$baseServerUrl/builds/$buildJobId/runs/$runId/steps');

  final body = jsonEncode({
    'id': stepId,
    'runId': runId,
    'name': name,
    'status': status,
    'durationMs': durationMs,
    'stepOrder': stepOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  });

  final client = http.Client();
  try {
    final response = await client
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            if (_internalApiKey != null)
              'Authorization': 'Bearer $_internalApiKey',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _log.warning('Failed to send step status update: ${response.statusCode}');
    }
  } catch (e) {
    _log.warning('Failed to send step status update: $e');
  } finally {
    client.close();
  }
}
