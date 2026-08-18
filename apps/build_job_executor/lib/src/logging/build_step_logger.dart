import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:logging/logging.dart' as dart_logging;
import 'package:build_job_executor/src/logging/loki_api_service.dart';

final _log = dart_logging.Logger('BuildStepLog');

String? _lokiUrl;
LokiApiService? _lokiApiService;

class LokiJsonConverter extends JsonConverter {
  const LokiJsonConverter();

  @override
  FutureOr<Response<BodyType>> convertResponse<BodyType, InnerType>(
    Response response,
  ) {
    if (response.bodyString.isEmpty) {
      return response.copyWith<BodyType>(body: null);
    }
    return super.convertResponse<BodyType, InnerType>(response);
  }
}

void setupBuildStepLogger({
  String? serverUrl,
  String? internalApiKey,
  String? lokiUrl,
}) {
  _lokiUrl =
      lokiUrl ?? Platform.environment['LOKI_URL'] ?? 'http://localhost:3100';

  final chopperClient = ChopperClient(
    baseUrl: Uri.parse(_lokiUrl!),
    services: [LokiApiService.create()],
    converter: const LokiJsonConverter(),
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
    converter: const LokiJsonConverter(),
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
    labels: {
      'build_job_id': buildJobId,
      'run_id': runId,
      'step_id': stepId,
      'type': 'step_log',
    },
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

/// ステップのステータス変更イベントを Loki へ Push 送信
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
  final eventMessage = jsonEncode({
    'id': stepId,
    'runId': runId,
    'name': name,
    'status': status,
    'durationMs': durationMs,
    'stepOrder': stepOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  });

  final payload = createLokiPayload(
    labels: {
      'build_job_id': buildJobId,
      'run_id': runId,
      'step_id': stepId,
      'type': 'step_event',
    },
    message: eventMessage,
  );

  try {
    final response = await _getLokiService().pushLogs(payload);
    if (!response.isSuccessful) {
      _log.warning(
        'Failed to push step status update to Loki: HTTP ${response.statusCode}',
      );
    }
  } catch (e) {
    _log.warning('Error pushing step status update to Loki: $e');
  }
}
