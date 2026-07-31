import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:openci_server/logging/loki_service.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
  String runId,
) async {
  final handler = webSocketHandler((channel, protocol) async {
    final lokiBaseUrl =
        Platform.environment['LOKI_URL'] ?? 'http://localhost:3100';
    final lokiWsScheme = lokiBaseUrl.startsWith('https') ? 'wss' : 'ws';
    final lokiHost = lokiBaseUrl
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll('/', '');

    final lokiTailUri = Uri.parse(
      '$lokiWsScheme://$lokiHost/loki/api/v1/tail?query={run_id="$runId"}',
    );

    WebSocketChannel? lokiChannel;
    try {
      lokiChannel = WebSocketChannel.connect(lokiTailUri);

      lokiChannel.stream.listen(
        (data) {
          final frameStr = data.toString();
          final parsedEntries = LokiService.parseTailFrame(frameStr);

          for (final entry in parsedEntries) {
            final labels = entry.key;
            final message = entry.value;

            // step_event またはステップ/全体ログを構造化して送信
            final isStepEvent =
                labels['type'] == 'step_event' ||
                (message.trim().startsWith('{') &&
                    message.contains('"stepOrder"'));

            final payload = <String, dynamic>{
              'runId': runId,
              'stepId': labels['step_id'],
              'isStepEvent': isStepEvent,
              'message': message,
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            };

            channel.sink.add(jsonEncode(payload));
          }
        },
        onError: (dynamic error) {
          stderr.writeln('[WebSocket stream.dart] Loki stream error: $error');
        },
        onDone: () {
          unawaited(channel.sink.close());
        },
      );

      channel.stream.listen(
        (dynamic message) {
          // クライアントからのメッセージ（ping等）を受信可能な構成
        },
        onDone: () {
          unawaited(lokiChannel?.sink.close());
        },
        onError: (dynamic error) {
          unawaited(lokiChannel?.sink.close());
        },
      );
    } catch (e, s) {
      stderr.writeln(
        '[WebSocket stream.dart] Failed to connect to Loki tail API: $e\n$s',
      );
      unawaited(channel.sink.close());
    }
  });

  return handler(context);
}
