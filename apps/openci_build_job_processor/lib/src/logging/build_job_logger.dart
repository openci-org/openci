import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:logging/logging.dart' as dart_logging;
import 'package:openci_build_job_processor/src/logging/loki_api_service.dart';

final _log = dart_logging.Logger('BuildLog');

enum LogLevel { info, warning, error }

String? _lokiUrl;
LokiApiService? _lokiApiService;

void setupBuildJobLogger({
  String? serverUrl,
  String? internalApiKey,
  String? lokiUrl,
}) {
  _lokiUrl =
      lokiUrl ?? Platform.environment['LOKI_URL'] ?? 'http://localhost:3100';

  final chopperClient = ChopperClient(
    baseUrl: Uri.parse(_lokiUrl!),
    services: [LokiApiService.create()],
    converter: const JsonConverter(),
  );
  _lokiApiService = chopperClient.getService<LokiApiService>();

  dart_logging.Logger.root.level = dart_logging.Level.ALL;
  dart_logging.Logger.root.onRecord.listen((record) {
    final jstTime = record.time.toUtc().add(const Duration(hours: 9));
    final timeStr = jstTime.toString().length >= 23
        ? jstTime.toString().substring(5, 23)
        : jstTime.toString();
    stdout.writeln(
      '$timeStr [${record.loggerName}] ${record.level.name}: ${record.message}',
    );
    if (record.error != null) {
      stdout.writeln('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      stdout.writeln('StackTrace:\n${record.stackTrace}');
    }
  });
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

Future<void> writeBuildLog(
  String buildJobId,
  String runId,
  LogLevel level,
  String message, {
  String? stepId,
  String? stackTrace,
}) async {
  if (message.isEmpty) return;

  final formattedMsg = stackTrace != null ? '$message\n$stackTrace' : message;

  final payload = createLokiPayload(
    labels: {
      'build_job_id': buildJobId,
      'run_id': runId,
      if (stepId != null && stepId.isNotEmpty) 'step_id': stepId,
    },
    message: formattedMsg,
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

Future<void> logInfo(
  String buildJobId,
  String runId,
  String message, {
  String? stepId,
}) async {
  _log.info(message);
  await writeBuildLog(
    buildJobId,
    runId,
    LogLevel.info,
    message,
    stepId: stepId,
  );
}

Future<void> logWarning(
  String buildJobId,
  String runId,
  String message, {
  String? stepId,
}) async {
  _log.warning(message);
  await writeBuildLog(
    buildJobId,
    runId,
    LogLevel.warning,
    message,
    stepId: stepId,
  );
}

Future<void> logError(
  String buildJobId,
  String runId,
  String message, {
  String? stepId,
  String? stackTrace,
}) async {
  _log.severe(message);
  if (stackTrace != null) {
    _log.severe('Stack trace: $stackTrace');
  }
  await writeBuildLog(
    buildJobId,
    runId,
    LogLevel.error,
    message,
    stepId: stepId,
    stackTrace: stackTrace,
  );
}

/// `act` の出力の "[Workflow/Job]" プレフィックスを "[Job]" の短い形式に短縮します。
String stripActPrefix(String line) {
  final pattern = RegExp(r'^\[([^\]]+)\]\s*(.*)$');
  final match = pattern.firstMatch(line);
  if (match != null) {
    final prefixContent = match.group(1) ?? '';
    final msg = match.group(2) ?? '';
    if (msg.isNotEmpty) {
      final slashIndex = prefixContent.lastIndexOf('/');
      final shortJobName = slashIndex != -1
          ? prefixContent.substring(slashIndex + 1).trim()
          : prefixContent.trim();
      return '[$shortJobName] $msg';
    }
  }
  return line;
}
