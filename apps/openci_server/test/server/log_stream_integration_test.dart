import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openci_server/db.dart';
import 'package:openci_server/log_stream_manager.dart';
import 'package:openci_server/middleware.dart';
import 'package:openci_server/router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../storage/fake_storage.dart';

void main() {
  group('LogStreamManager and WebSocket API Tests', () {
    late LogStreamManager manager;
    late FakeStorageManager storage;
    late DatabaseManager db;
    late HttpServer server;
    late int port;

    setUpAll(() async {
      manager = LogStreamManager();
      storage = FakeStorageManager();
      db = DatabaseManager(
        'postgres://postgres:password@localhost:5432/openci_test',
      );

      final handler = applyMiddleware(getRouter(db, storage));
      server = await shelf_io.serve(handler, 'localhost', 0);
      port = server.port;
    });

    tearDownAll(() async {
      await server.close(force: true);
      await db.close();
    });

    test('LogStreamManager buffers and streams logs correctly', () async {
      final runId = 'test-run-${DateTime.now().millisecondsSinceEpoch}';
      manager.initSession(runId);

      expect(manager.hasSession(runId), isTrue);

      final logs = <String>[];
      final stream = manager.getStream(runId);
      final subscription = stream?.listen((msg) => logs.add(msg));

      manager.appendLog(runId, 'Log line 1');
      manager.appendLog(runId, 'Log line 2');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(logs, equals(['Log line 1', 'Log line 2']));
      expect(manager.getBuffer(runId), equals(['Log line 1', 'Log line 2']));

      await subscription?.cancel();
      await manager.finalizeSession(runId, storage);

      expect(manager.hasSession(runId), isFalse);

      final savedData = await storage.downloadObject('logs/$runId.log');
      final savedBytes = await savedData.expand((c) => c).toList();
      final savedText = utf8.decode(savedBytes);
      expect(savedText, equals('Log line 1\nLog line 2\n'));
    });

    test(
      'WebSocket stream endpoint works and relays logs in real-time',
      () async {
        final runId = 'test-run-ws-${DateTime.now().millisecondsSinceEpoch}';
        final buildJobId = 'test-job-ws';

        final client = http.Client();
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
        final subscription = channel.stream.listen((msg) {
          receivedLogs.add(msg as String);
        });

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

        final completeUrl = Uri.parse(
          'http://localhost:$port/builds/$buildJobId/runs/$runId/complete',
        );
        await client.post(completeUrl);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(manager.hasSession(runId), isFalse);

        final savedData = await storage.downloadObject('logs/$runId.log');
        final savedBytes = await savedData.expand((c) => c).toList();
        final savedText = utf8.decode(savedBytes);
        expect(savedText, contains('Real-time log 3'));

        await subscription.cancel();
        client.close();
      },
    );
  });
}
