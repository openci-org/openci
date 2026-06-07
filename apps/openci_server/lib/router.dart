import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:openci_server/db.dart';
import 'package:openci_server/logger_manager.dart';
import 'package:openci_server/storage.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Router getRouter(
  DatabaseManager db,
  StorageManager storage, {
  Map<String, String>? environment,
}) {
  final router = Router();
  final env = environment ?? Platform.environment;
  final appEnv = env['APP_ENV'] ?? 'development';

  router.get('/', (Request request) {
    return Response.ok(
      'OpenCI Server (Shelf) is running!\n',
      headers: {'content-type': 'text/plain'},
    );
  });

  router.get('/health', (Request request) async {
    bool dbHealthy;
    try {
      dbHealthy = await db.verifyConnection();
    } catch (_) {
      dbHealthy = false;
    }

    bool storageHealthy;
    try {
      storageHealthy = await storage.verifyConnection();
    } catch (_) {
      storageHealthy = false;
    }

    final status = (dbHealthy && storageHealthy) ? 'ok' : 'error';
    final responseBody = {
      'status': status,
      'database': dbHealthy ? 'connected' : 'disconnected',
      'storage': storageHealthy ? 'connected' : 'disconnected',
    };

    return Response(
      (dbHealthy && storageHealthy) ? 200 : 500,
      body: jsonEncode(responseBody),
      headers: {'content-type': 'application/json'},
    );
  });

  router.post('/test-upload', (Request request) async {
    if (appEnv == 'production') {
      return Response.forbidden(
        jsonEncode({
          'success': false,
          'error': 'Test upload is disabled in production environment.',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    try {
      final testFileName = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';
      final testContent =
          'Hello, this is a test artifact uploaded from OpenCI Server!';
      final stream = Stream.value(Uint8List.fromList(utf8.encode(testContent)));

      await storage.uploadObject(
        testFileName,
        stream,
        size: testContent.length,
      );

      final downloadUrl = await storage.getPresignedUrl(testFileName);

      return Response.ok(
        jsonEncode({
          'success': true,
          'file': testFileName,
          'downloadUrl': downloadUrl,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, s) {
      stderr.writeln('Test upload failed: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  router.post('/builds/<buildJobId>/runs/<runId>/logs', (
    Request request,
    String buildJobId,
    String runId,
  ) async {
    try {
      final payload =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final logs = payload['logs'] as List<dynamic>? ?? [];

      for (final log in logs) {
        if (log is Map) {
          final message = log['message'] as String?;
          if (message != null) {
            LogStreamManager().appendLog(runId, message);
          }
        }
      }

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, s) {
      stderr.writeln('Failed to append logs for run $runId: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  router.get('/builds/<buildJobId>/runs/<runId>/logs/stream', (
    Request request,
    String buildJobId,
    String runId,
  ) {
    return webSocketHandler((WebSocketChannel webSocket, String? protocol) {
      final manager = LogStreamManager();
      manager.initSession(runId);

      final buffer = manager.getBuffer(runId);
      for (final logLine in buffer) {
        webSocket.sink.add(logLine);
      }

      final stream = manager.getStream(runId);
      StreamSubscription<String>? subscription;
      if (stream != null) {
        subscription = stream.listen(
          (message) {
            webSocket.sink.add(message);
          },
          onError: (err) {
            webSocket.sink.close();
          },
          onDone: () {
            webSocket.sink.close();
          },
        );
      }

      webSocket.stream.listen(
        null,
        onDone: () {
          subscription?.cancel();
        },
      );
    })(request);
  });

  router.post('/builds/<buildJobId>/runs/<runId>/complete', (
    Request request,
    String buildJobId,
    String runId,
  ) async {
    try {
      await LogStreamManager().finalizeSession(runId, storage);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, s) {
      stderr.writeln('Failed to finalize log session for run $runId: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  return router;
}
