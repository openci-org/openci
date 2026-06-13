import 'dart:async';
import 'dart:convert';

import 'package:dashboard/build_logs/build_logs_provider.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_job_logs_provider.g.dart';

@riverpod
class BuildJobLogs extends _$BuildJobLogs {
  http.Client? _client;
  StreamSubscription<String>? _subscription;

  @override
  Stream<List<BuildLog>> build(String buildJobId, String runId) {
    final controller = StreamController<List<BuildLog>>();
    final List<BuildLog> logs = [];

    controller.add(logs);

    ref.onDispose(() {
      _subscription?.cancel();
      _client?.close();
      controller.close();
    });

    _connectSse(buildJobId, runId, controller, logs);

    return controller.stream;
  }

  String get serverUrl {
    final serverUrl = String.fromEnvironment('OPENCI_SERVER_URL');
    if (serverUrl.isEmpty) {
      throw UnimplementedError('OPENCI_SERVER_URL is not set');
    }
    return serverUrl;
  }

  void _connectSse(
    String buildJobId,
    String runId,
    StreamController<List<BuildLog>> controller,
    List<BuildLog> logs,
  ) async {
    final url = Uri.parse(
      '$serverUrl/build_job/$buildJobId/runs/$runId/logs/stream',
    );

    _client = http.Client();
    final request = http.Request('GET', url)
      ..headers['Accept'] = 'text/event-stream'
      ..headers['Cache-Control'] = 'no-cache';

    try {
      final response = await _client!.send(request);
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
              logs.add(log);
              if (!controller.isClosed) {
                controller.add(List<BuildLog>.from(logs));
              }
            } catch (e, s) {
              if (!controller.isClosed) {
                controller.addError(e, s);
              }
            }
          } else if (line.startsWith('event: done')) {
            _client?.close();
            _subscription?.cancel();
            if (!controller.isClosed) {
              controller.close();
            }
          }
        },
        onError: (Object e, StackTrace st) {
          if (!controller.isClosed) {
            controller.addError(e, st);
          }
        },
        onDone: () {
          if (!controller.isClosed) {
            controller.close();
          }
        },
      );
    } catch (e, st) {
      if (!controller.isClosed) {
        controller.addError(e, st);
      }
      _client?.close();
    }
  }
}
