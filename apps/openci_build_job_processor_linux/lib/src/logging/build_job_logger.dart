import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart' as dart_logging;

final _log = dart_logging.Logger('BuildLog');

enum LogLevel { info, warning, error }

String? _lokiUrl;
final http.Client _client = http.Client();

void setupBuildJobLogger({
  String? serverUrl,
  String? internalApiKey,
  String? lokiUrl,
}) {
  _lokiUrl =
      lokiUrl ?? Platform.environment['LOKI_URL'] ?? 'http://localhost:3100';

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

Future<void> writeBuildLog(
  String buildJobId,
  String runId,
  LogLevel level,
  String message, {
  String? stackTrace,
}) async {
  if (message.isEmpty) return;

  final lokiBaseUrl = _lokiUrl ?? 'http://localhost:3100';
  final nowNanos = (DateTime.now().toUtc().microsecondsSinceEpoch * 1000)
      .toString();

  final formattedMsg = stackTrace != null ? '$message\n$stackTrace' : message;

  final payload = {
    'streams': [
      {
        'stream': {'build_job_id': buildJobId, 'run_id': runId},
        'values': [
          [nowNanos, formattedMsg],
        ],
      },
    ],
  };

  try {
    final response = await _client
        .post(
          Uri.parse('$lokiBaseUrl/loki/api/v1/push'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode >= 300) {
      _log.warning('Failed to push log to Loki: HTTP ${response.statusCode}');
    }
  } catch (e) {
    _log.warning('Error pushing log to Loki: $e');
  }
}

Future<void> logInfo(String buildJobId, String runId, String message) async {
  _log.info(message);
  await writeBuildLog(buildJobId, runId, LogLevel.info, message);
}

Future<void> logWarning(String buildJobId, String runId, String message) async {
  _log.warning(message);
  await writeBuildLog(buildJobId, runId, LogLevel.warning, message);
}

Future<void> logError(
  String buildJobId,
  String runId,
  String message, {
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
    stackTrace: stackTrace,
  );
}

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
