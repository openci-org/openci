import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart' as dart_logging;
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

Future<void> _sendLogsWithRetry(
  String buildJobId,
  String runId,
  List<LogEntry> logs,
) async {
  final client = _apiClient;
  if (client == null) {
    _log.warning('ApiClient not configured for logging. Logs will be discarded.');
    return;
  }

  final payloadLogs = logs.map((e) => e.toJson()).toList();

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
        _log.warning('[BuildLog] Failed to send bulk logs: $e');
        return;
      }
      final delay = _initialRetryDelay * (1 << (attempt - 1));
      await Future.delayed(delay);
    }
  }
}

void _triggerFlush(_BufferGroup group) {
  group.timer?.cancel();
  group.timer = null;

  if (group.entries.isEmpty) return;

  final logsToSend = List<LogEntry>.from(group.entries);
  group.entries.clear();

  final writeFuture = _sendLogsWithRetry(group.buildJobId, group.runId, logsToSend);
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
  group.entries.add(LogEntry(
    id: _uuid.v4(),
    message: message,
    level: level,
    timestamp: DateTime.now().toUtc().toIso8601String(),
    stackTrace: stackTrace,
  ));

  if (group.entries.length >= _maxBufferCount) {
    _triggerFlush(group);
  } else {
    group.timer ??= Timer(_flushInterval, () => _triggerFlush(group));
  }
}

Future<void> flushRemainingLogs() async {
  for (final group in _bufferGroups.values) {
    _triggerFlush(group);
  }

  while (_activeWrites.isNotEmpty) {
    await Future.wait(_activeWrites);
  }
}

Future<void> logInfo(
  String buildJobId,
  String runId,
  String message,
) async {
  _log.info(message);
  await writeBuildLog(buildJobId, runId, LogLevel.info, message);
}

Future<void> logWarning(
  String buildJobId,
  String runId,
  String message,
) async {
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
    stdout.writeln('${record.time} [${record.loggerName}] ${record.level.name}: ${record.message}');
    stdout.flush();
  });
}
