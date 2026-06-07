import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart' as dart_logging;
import 'package:uuid/uuid.dart';

import 'cloud_function_caller.dart';

final _log = dart_logging.Logger('BuildLog');
const _uuid = Uuid();

enum LogLevel { info, warning, error }

class LogEntry {
  final String id;
  final String message;
  final LogLevel level;
  final String timestamp;
  final String? stackTrace;

  LogEntry({
    required this.id,
    required this.message,
    required this.level,
    required this.timestamp,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'level': level.name,
    'timestamp': timestamp,
    if (stackTrace != null) 'stackTrace': stackTrace,
  };
}

class _BufferGroup {
  final String buildJobId;
  final String runId;
  List<LogEntry> entries = [];
  Timer? timer;

  _BufferGroup({required this.buildJobId, required this.runId});
}

ApiClient? _apiClient;
final _bufferGroups = <String, _BufferGroup>{};
final _activeWrites = <Future<void>>[];

void setLoggerApiClient(ApiClient apiClient) {
  _apiClient = apiClient;
}

_BufferGroup _getBufferGroup(String buildJobId, String runId) {
  final key = '$buildJobId:$runId';
  return _bufferGroups.putIfAbsent(
    key,
    () => _BufferGroup(buildJobId: buildJobId, runId: runId),
  );
}

const _maxBufferCount = 50;
const _flushInterval = Duration(seconds: 1);
const _maxWriteAttempts = 5;
const _initialRetryDelay = Duration(milliseconds: 500);

final http.Client _httpClient = http.Client();

Future<void> _sendLogsWithRetry(
  String buildJobId,
  String runId,
  List<LogEntry> logs,
) async {
  final payloadLogs = logs.map((e) => e.toJson()).toList();

  // 1. openci_server への送信
  final serverUrl =
      Platform.environment['OPENCI_SERVER_URL'] ?? 'http://localhost:8080';
  final url = Uri.parse('$serverUrl/builds/$buildJobId/runs/$runId/logs');
  final body = jsonEncode({'logs': payloadLogs});

  Future<void> sendToServer() async {
    for (var attempt = 1; attempt <= _maxWriteAttempts; attempt++) {
      try {
        final response = await _httpClient.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }
        throw HttpException('HTTP ${response.statusCode}: ${response.body}');
      } catch (e) {
        if (attempt == _maxWriteAttempts) {
          _log.warning('[BuildLog] Failed to send logs to server: $e');
          return;
        }
        final delay = _initialRetryDelay * (1 << (attempt - 1));
        await Future.delayed(delay);
      }
    }
  }

  // 2. Firebase Cloud Functions (Firestore) への送信
  Future<void> sendToFirebase() async {
    final client = _apiClient;
    if (client == null) return;

    for (var attempt = 1; attempt <= _maxWriteAttempts; attempt++) {
      try {
        await client.appendBuildLogs(
          buildJobId: buildJobId,
          runId: runId,
          logs: payloadLogs,
        );
        return;
      } catch (e) {
        if (attempt == _maxWriteAttempts) {
          _log.warning('[BuildLog] Failed to send logs to Firebase: $e');
          return;
        }
        final delay = _initialRetryDelay * (1 << (attempt - 1));
        await Future.delayed(delay);
      }
    }
  }

  // 両方の送信を並行して実行
  await Future.wait([sendToServer(), sendToFirebase()]);
}

void _triggerFlush(_BufferGroup group) {
  group.timer?.cancel();
  group.timer = null;

  if (group.entries.isEmpty) return;

  final logsToSend = List<LogEntry>.from(group.entries);
  group.entries.clear();

  final writeFuture = _sendLogsWithRetry(
    group.buildJobId,
    group.runId,
    logsToSend,
  );
  _activeWrites.add(writeFuture);
  writeFuture.whenComplete(() {
    _activeWrites.remove(writeFuture);
  });
}

Future<void> writeBuildLog(
  String buildJobId,
  String runId,
  LogLevel level,
  String message, {
  String? stackTrace,
}) async {
  final group = _getBufferGroup(buildJobId, runId);
  group.entries.add(
    LogEntry(
      id: _uuid.v4(),
      message: message,
      level: level,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      stackTrace: stackTrace,
    ),
  );

  if (group.entries.length >= _maxBufferCount) {
    _triggerFlush(group);
  } else {
    group.timer ??= Timer(_flushInterval, () => _triggerFlush(group));
  }
}

Future<void> flushRemainingLogs({String? runId}) async {
  for (final key in _bufferGroups.keys.toList()) {
    final group = _bufferGroups[key]!;
    if (runId == null || group.runId == runId) {
      _triggerFlush(group);
      _bufferGroups.remove(key);
    }
  }

  while (_activeWrites.isNotEmpty) {
    await Future.wait(_activeWrites);
  }
}

Future<void> finalizeBuildLog(String buildJobId, String runId) async {
  await flushRemainingLogs(runId: runId);

  final serverUrl =
      Platform.environment['OPENCI_SERVER_URL'] ?? 'http://localhost:8080';
  final url = Uri.parse('$serverUrl/builds/$buildJobId/runs/$runId/complete');

  const maxAttempts = 3;
  var delay = const Duration(milliseconds: 500);

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final response = await _httpClient
          .post(url)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
      if (attempt == maxAttempts) {
        _log.warning(
          '[BuildLog] Failed to send complete signal after $maxAttempts attempts. Final error: $errorMsg',
        );
      } else {
        _log.warning(
          '[BuildLog] Attempt $attempt failed to send complete signal: $errorMsg. Retrying in ${delay.inMilliseconds}ms...',
        );
      }
    } catch (e) {
      if (attempt == maxAttempts) {
        _log.warning(
          '[BuildLog] Failed to send complete signal after $maxAttempts attempts. Final exception: $e',
        );
      } else {
        _log.warning(
          '[BuildLog] Attempt $attempt failed to send complete signal with exception: $e. Retrying in ${delay.inMilliseconds}ms...',
        );
      }
    }

    if (attempt < maxAttempts) {
      await Future.delayed(delay);
      delay *= 2;
    }
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

void setupLogging() {
  dart_logging.Logger.root.level = dart_logging.Level.ALL;
  dart_logging.Logger.root.onRecord.listen((record) {
    stdout.writeln(
      '${record.time} [${record.loggerName}] ${record.level.name}: ${record.message}',
    );
    stdout.flush();
  });
}
