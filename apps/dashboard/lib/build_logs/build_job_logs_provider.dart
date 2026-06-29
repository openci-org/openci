import 'dart:async';
import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'build_job_logs_provider.freezed.dart';
part 'build_job_logs_provider.g.dart';

@freezed
abstract class BuildLog with _$BuildLog {
  const factory BuildLog({
    required String message,
    required String level,
    @DateTimeConverter() DateTime? timestamp,
  }) = _BuildLog;

  factory BuildLog.fromJson(Map<String, Object?> json) =>
      _$BuildLogFromJson(json);
}

@riverpod
Stream<List<BuildLog>> buildJobLogs(
  Ref ref,
  String buildJobId,
  String runId,
) async* {
  final serverUrl = ref.watch(openciServerUrlProvider);
  final wsUrl = serverUrl
      .replaceAll('https://', 'wss://')
      .replaceAll('http://', 'ws://');
  final url = Uri.parse('$wsUrl/builds/$buildJobId/runs/$runId/ws');
  final token = await ref.watch(authedFirebaseIdTokenProvider.future);

  final channel = WebSocketChannel.connect(url);

  var isDisposed = false;
  ref.onDispose(() {
    isDisposed = true;
    channel.sink.close();
  });

  // 1. 接続後に認証メッセージを送信
  channel.sink.add(
    jsonEncode({
      'type': 'auth',
      'token': token,
    }),
  );

  final accumulatedLogs = <BuildLog>[];
  yield const [];

  try {
    await for (final message in channel.stream) {
      final data = jsonDecode(message as String) as Map<String, dynamic>;

      if (data['type'] == 'log') {
        final content = data['content'] as String;
        // ログコンテンツを改行でスプリットし、1行ずつ追加する
        final lines = content.split('\n');
        for (final line in lines) {
          if (line.isEmpty && line == lines.last) continue;
          accumulatedLogs.add(
            BuildLog(
              message: line,
              level: 'info',
              timestamp: DateTime.now(),
            ),
          );
        }
        yield List<BuildLog>.from(accumulatedLogs);
      } else if (data['type'] == 'error') {
        throw Exception(data['message']);
      }
    }
  } catch (e) {
    if (isDisposed) {
      return;
    }
    rethrow;
  }
}
