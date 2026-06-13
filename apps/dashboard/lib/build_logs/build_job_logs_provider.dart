import 'dart:async';
import 'dart:convert';

import 'package:dashboard/build_logs/build_logs_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_job_logs_provider.g.dart';

@riverpod
class BuildJobLogs extends _$BuildJobLogs {
  http.Client? _client;
  StreamSubscription<String>? _subscription;
  Timer? _bufferTimer;

  @override
  Stream<List<BuildLog>> build(
    String buildJobId,
    String runId,
    BuildJobStatus buildStatus,
  ) {
    final controller = StreamController<List<BuildLog>>();
    final List<BuildLog> logs = [];

    controller.add(logs);

    ref.onDispose(() {
      _subscription?.cancel();
      _client?.close();
      _bufferTimer?.cancel();
      unawaited(controller.close());
    });

    _initializeLogs(buildJobId, runId, buildStatus, controller, logs);

    return controller.stream;
  }

  String get serverUrl {
    const serverUrl = String.fromEnvironment('OPENCI_SERVER_URL');
    if (serverUrl.isEmpty) {
      throw UnimplementedError('OPENCI_SERVER_URL is not set');
    }
    return serverUrl;
  }

  void _initializeLogs(
    String buildJobId,
    String runId,
    BuildJobStatus buildStatus,
    StreamController<List<BuildLog>> controller,
    List<BuildLog> logs,
  ) async {
    try {
      final isRunning =
          buildStatus == BuildJobStatus.IN_PROGRESS ||
          buildStatus == BuildJobStatus.QUEUED ||
          buildStatus == BuildJobStatus.WAITING;

      if (isRunning) {
        // 実行中の場合は SSE に接続してリアルタイム受信
        unawaited(_connectSse(buildJobId, runId, controller, logs));
      } else {
        // 完了済みの場合は HTTP GET で一括取得して完了する
        unawaited(_fetchLogsOnce(buildJobId, runId, controller, logs));
      }
    } catch (e, st) {
      if (!controller.isClosed) {
        controller.addError(e, st);
      }
    }
  }

  Future<void> _fetchLogsOnce(
    String buildJobId,
    String runId,
    StreamController<List<BuildLog>> controller,
    List<BuildLog> logs,
  ) async {
    final url = Uri.parse(
      '$serverUrl/builds/$buildJobId/runs/$runId/logs',
    );

    debugPrint('SSE/HTTP: Fetching static logs from: $url');

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      if (!controller.isClosed) {
        controller.addError(
          Exception('Unauthorized: No user is currently signed in'),
          StackTrace.current,
        );
      }
      return;
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'SSE/HTTP: Static logs response status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        if (!controller.isClosed) {
          controller.addError(
            Exception('Failed to fetch logs: ${response.statusCode}'),
          );
        }
        return;
      }

      final logText = response.body;
      if (logText.isNotEmpty) {
        final lines = logText.split('\n');
        for (final line in lines) {
          if (line.isEmpty) continue;
          logs.add(
            BuildLog(
              message: line,
              level: 'info',
              timestamp: DateTime.now(),
            ),
          );
        }
      }

      if (!controller.isClosed) {
        controller.add(List<BuildLog>.from(logs));
        unawaited(controller.close());
      }
    } catch (e, st) {
      if (!controller.isClosed) {
        controller.addError(e, st);
      }
    }
  }

  Future<void> _connectSse(
    String buildJobId,
    String runId,
    StreamController<List<BuildLog>> controller,
    List<BuildLog> logs,
  ) async {
    final url = Uri.parse(
      '$serverUrl/builds/$buildJobId/runs/$runId/logs/stream',
    );

    debugPrint('SSE: Connecting to: $url');

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      if (!controller.isClosed) {
        controller.addError(
          Exception('Unauthorized: No user is currently signed in'),
          StackTrace.current,
        );
      }
      return;
    }

    _client = http.Client();
    final request = http.Request('GET', url)
      ..headers['Accept'] = 'text/event-stream'
      ..headers['Cache-Control'] = 'no-cache'
      ..headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _client!.send(request);
      debugPrint('SSE: Connected response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        if (!controller.isClosed) {
          controller.addError(
            Exception('Failed to connect to SSE: ${response.statusCode}'),
            StackTrace.current,
          );
        }
        return;
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      final List<BuildLog> pendingLogs = [];

      void flushPendingLogs() {
        if (pendingLogs.isEmpty) return;
        logs.addAll(pendingLogs);
        pendingLogs.clear();
        if (!controller.isClosed) {
          controller.add(List<BuildLog>.from(logs));
        }
      }

      _subscription = stream.listen(
        (line) {
          if (line.isEmpty) return;

          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr == '{}' || dataStr.isEmpty) return;

            try {
              final data = jsonDecode(dataStr) as Map<String, dynamic>;
              final log = BuildLog(
                message: data['content'] as String? ?? '',
                level: data['level'] as String? ?? 'info',
                timestamp: data['createdAt'] != null
                    ? DateTime.parse(data['createdAt'] as String)
                    : DateTime.now(),
              );
              pendingLogs.add(log);

              if (_bufferTimer == null || !_bufferTimer!.isActive) {
                _bufferTimer = Timer(const Duration(milliseconds: 50), () {
                  flushPendingLogs();
                });
              }
            } catch (e, s) {
              debugPrint('SSE: Parse error: $e\n$s');
              if (!controller.isClosed) {
                controller.addError(e, s);
              }
            }
          } else if (line.startsWith('event: done')) {
            debugPrint('SSE: Done event received');
            _bufferTimer?.cancel();
            flushPendingLogs();
            _client?.close();
            _subscription?.cancel();
            if (!controller.isClosed) {
              unawaited(controller.close());
            }
          }
        },
        onError: (Object e, StackTrace st) {
          debugPrint('SSE: onError: $e\n$st');
          _bufferTimer?.cancel();
          flushPendingLogs();
          if (!controller.isClosed) {
            controller.addError(e, st);
          }
        },
        onDone: () {
          debugPrint('SSE: Stream onDone');
          _bufferTimer?.cancel();
          flushPendingLogs();
          if (!controller.isClosed) {
            unawaited(controller.close());
          }
        },
      );
    } catch (e, st) {
      debugPrint('SSE: Connection error: $e\n$st');
      if (!controller.isClosed) {
        controller.addError(e, st);
      }
      _client?.close();
    }
  }
}
