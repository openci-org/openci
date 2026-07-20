import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart' as dart_logging;
import 'package:uuid/uuid.dart';

final _log = dart_logging.Logger('BuildStepLog');
const _uuid = Uuid();

class StepLogEntry {
  final String id;
  final String message;
  final String timestamp;

  StepLogEntry({
    required this.id,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'timestamp': timestamp,
  };
}

class _StepBufferGroup {
  final String buildJobId;
  final String runId;
  final String stepId;
  List<StepLogEntry> entries = [];
  Timer? timer;

  _StepBufferGroup({
    required this.buildJobId,
    required this.runId,
    required this.stepId,
  });
}

String? _serverUrl;
String? _internalApiKey;
final _stepBufferGroups = <String, _StepBufferGroup>{};
final _activeWrites = <Future<void>>[];

const _maxBufferCount = 50;
const _flushInterval = Duration(seconds: 1);
const _maxWriteAttempts = 5;
const _initialRetryDelay = Duration(milliseconds: 500);

void setupBuildStepLogger({
  required String serverUrl,
  required String internalApiKey,
}) {
  _serverUrl = serverUrl;
  _internalApiKey = internalApiKey;
}

_StepBufferGroup _getBufferGroup(
  String buildJobId,
  String runId,
  String stepId,
) {
  final key = '$buildJobId:$runId:$stepId';
  return _stepBufferGroups.putIfAbsent(
    key,
    () =>
        _StepBufferGroup(buildJobId: buildJobId, runId: runId, stepId: stepId),
  );
}

Future<void> _sendStepLogsWithRetry(
  String buildJobId,
  String runId,
  String stepId,
  List<StepLogEntry> logs,
) async {
  final payloadLogs = logs.map((e) => e.toJson()).toList();

  final baseServerUrl = _serverUrl ?? 'http://localhost:8080';
  final url = Uri.parse(
    '$baseServerUrl/builds/$buildJobId/runs/$runId/steps/$stepId/logs',
  );
  final body = jsonEncode({'logs': payloadLogs});

  final client = http.Client();
  try {
    for (var attempt = 1; attempt <= _maxWriteAttempts; attempt++) {
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
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }
        throw HttpException('HTTP ${response.statusCode}: ${response.body}');
      } catch (e) {
        if (attempt == _maxWriteAttempts) {
          _log.warning('[BuildStepLog] Failed to send step logs to server: $e');
          return;
        }
        final delay = _initialRetryDelay * (1 << (attempt - 1));
        await Future.delayed(delay);
      }
    }
  } finally {
    client.close();
  }
}

void _triggerFlush(_StepBufferGroup group) {
  group.timer?.cancel();
  group.timer = null;

  if (group.entries.isEmpty) return;

  final logsToSend = List<StepLogEntry>.from(group.entries);
  group.entries.clear();

  final writeFuture = _sendStepLogsWithRetry(
    group.buildJobId,
    group.runId,
    group.stepId,
    logsToSend,
  );
  _activeWrites.add(writeFuture);
  writeFuture.whenComplete(() {
    _activeWrites.remove(writeFuture);
  });
}

Future<void> writeBuildStepLog(
  String buildJobId,
  String runId,
  String stepId,
  String message,
) async {
  final group = _getBufferGroup(buildJobId, runId, stepId);
  group.entries.add(
    StepLogEntry(
      id: _uuid.v4(),
      message: message,
      timestamp: DateTime.now().toUtc().toIso8601String(),
    ),
  );

  if (group.entries.length >= _maxBufferCount) {
    _triggerFlush(group);
  } else {
    group.timer ??= Timer(_flushInterval, () => _triggerFlush(group));
  }
}

Future<void> flushRemainingStepLogs({String? runId}) async {
  for (final key in _stepBufferGroups.keys.toList()) {
    final group = _stepBufferGroups[key]!;
    if (runId == null || group.runId == runId) {
      _triggerFlush(group);
      _stepBufferGroups.remove(key);
    }
  }

  try {
    await Future.wait(_activeWrites).timeout(const Duration(seconds: 5));
  } catch (_) {}
  _activeWrites.clear();
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
