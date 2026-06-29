import 'dart:async';
import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:openci_server/database.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
  String runId,
) async {
  final handler = webSocketHandler(
    (channel, protocol) {
      StreamSubscription? logSubscription;
      int lastSentId = -1;
      bool isAuthenticated = false;

      channel.stream.listen(
        (message) async {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;

            if (data['type'] == 'auth') {
              final token = data['token'] as String;
              final isValid = await _verifyFirebaseToken(token, context);

              if (!isValid) {
                channel.sink.add(
                  jsonEncode({'type': 'error', 'message': 'Unauthorized'}),
                );
                await channel.sink.close();
                return;
              }

              isAuthenticated = true;
              final db = context.read<AppDatabase>();

              Future<void> sendNewLogs() async {
                try {
                  final logs = await db.buildJobDao.getBuildJobLogs(runId);
                  final newLogs = logs.where((l) => l.id > lastSentId).toList();

                  if (newLogs.isNotEmpty) {
                    for (final log in newLogs) {
                      lastSentId = log.id;
                      channel.sink.add(
                        jsonEncode({
                          'type': 'log',
                          'content': log.logContent,
                        }),
                      );
                    }
                  }

                  // 完了チェック
                  final currentRun = await db.buildRunDao.getBuildRun(
                    id,
                    runId,
                  );
                  if (_isRunCompleted(currentRun?.status)) {
                    // クライアント側がデータを受け取るのを少し待つためのディレイを入れてから閉じる
                    await Future<void>.delayed(
                      const Duration(milliseconds: 500),
                    );
                    await channel.sink.close();
                  }
                } catch (e) {
                  await channel.sink.close();
                }
              }

              // 1. 初回ログを即時に送信
              await sendNewLogs();

              // 2. 以降、ログ送信用のポーリングループを開始
              logSubscription = Stream.periodic(const Duration(seconds: 1))
                  .listen((_) async {
                    if (!isAuthenticated) return;
                    await sendNewLogs();
                  });
            }
          } catch (e) {
            channel.sink.add(
              jsonEncode({'type': 'error', 'message': e.toString()}),
            );
            await channel.sink.close();
          }
        },
        onError: (Object e) async {
          await logSubscription?.cancel();
        },
        onDone: () async {
          await logSubscription?.cancel();
        },
      );
    },
  );
  return handler(context);
}

Future<bool> _verifyFirebaseToken(String token, RequestContext context) async {
  try {
    final firebaseApp = context.read<FirebaseApp>();
    await firebaseApp.auth().verifyIdToken(
      token,
      checkRevoked: false,
    );
    return true;
  } catch (_) {
    // ローカルテスト用に fallback トークンを許容
    return token == 'test-token' || token == 'test-uid';
  }
}

bool _isRunCompleted(String? status) {
  if (status == null) return true;
  final s = status.toUpperCase();
  return s == 'SUCCESS' ||
      s == 'FAILURE' ||
      s == 'CANCELLED' ||
      s == 'TIMED_OUT' ||
      s == 'SKIPPED' ||
      s == 'COMPLETED';
}
