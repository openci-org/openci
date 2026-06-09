import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/middleware.dart';
import 'package:openci_server/router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../storage/fake_storage.dart';

void main() {
  group('WebSocket API Tests', () {
    late FakeStorageManager storage;
    late AppDatabase db;
    late HttpServer server;
    late int port;

    setUpAll(() async {
      storage = FakeStorageManager();
      db = AppDatabase(NativeDatabase.memory());

      final handler = applyMiddleware(getRouter(storage, db: db));
      server = await shelf_io.serve(handler, 'localhost', 0);
      port = server.port;
    });

    tearDownAll(() async {
      await server.close(force: true);
      await db.close();
    });

    test(
      'WebSocket stream endpoint works and relays logs in real-time',
      () async {
        final runId = 'test-run-ws-${DateTime.now().millisecondsSinceEpoch}';
        final buildJobId =
            'test-job-ws-${DateTime.now().millisecondsSinceEpoch}';

        final client = http.Client();

        final buildsUrl = Uri.parse('http://localhost:$port/builds');
        await client.post(
          buildsUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': buildJobId,
            'status': 'IN_PROGRESS',
            'owner': 'test-owner',
            'repo': 'test-repo',
            'workflowName': 'test-workflow',
            'createdAt': DateTime.now().toUtc().toIso8601String(),
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          }),
        );

        final logsUrl = Uri.parse(
          'http://localhost:$port/builds/$buildJobId/runs/$runId/logs',
        );

        await client.post(
          logsUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'logs': [
              {'message': 'Pre-existing log 1'},
              {'message': 'Pre-existing log 2'},
            ],
          }),
        );

        final wsUrl = Uri.parse(
          'ws://localhost:$port/builds/$buildJobId/runs/$runId/logs/stream',
        );
        final channel = WebSocketChannel.connect(wsUrl);

        final receivedLogs = <String>[];
        final wsClosed = Completer<void>();
        final subscription = channel.stream.listen(
          (msg) {
            receivedLogs.add(msg as String);
          },
          onDone: () {
            if (!wsClosed.isCompleted) {
              wsClosed.complete();
            }
          },
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          receivedLogs,
          equals(['Pre-existing log 1', 'Pre-existing log 2']),
        );

        await client.post(
          logsUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'logs': [
              {'message': 'Real-time log 3'},
            ],
          }),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          receivedLogs,
          equals([
            'Pre-existing log 1',
            'Pre-existing log 2',
            'Real-time log 3',
          ]),
        );

        final patchUrl = Uri.parse('http://localhost:$port/builds/$buildJobId');
        await client.patch(
          patchUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': 'SUCCESS'}),
        );

        await wsClosed.future.timeout(const Duration(seconds: 2));

        final dbLogs = await db.buildJobDao.getBuildJobLogs(runId);
        final combinedLogText = dbLogs.map((l) => l.logContent).join('');
        expect(combinedLogText, contains('Pre-existing log 1'));
        expect(combinedLogText, contains('Pre-existing log 2'));
        expect(combinedLogText, contains('Real-time log 3'));

        await subscription.cancel();
        client.close();
      },
    );
  });
}
