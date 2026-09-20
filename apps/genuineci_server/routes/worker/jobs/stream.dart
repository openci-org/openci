import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:genuineci_server/auth/internal_api_key_validator.dart';
import 'package:genuineci_server/database.dart';
import 'package:meta/meta.dart';

Future<Response> onRequest(RequestContext context) =>
    handleRequest(context, const InternalApiKeyValidator());

@visibleForTesting
Future<Response> handleRequest(
  RequestContext context,
  InternalApiKeyValidator validator,
) async {
  if (validator.isValid(context) == false) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'success': false, 'error': 'Authentication required'},
    );
  }

  final handler = webSocketHandler((channel, protocol) async {
    final db = context.read<AppDatabase>();
    StreamSubscription<List<DriftBuildJob>>? dbSub;

    try {
      dbSub = db.buildJobDao.watchQueuedJobs().listen(
        (queuedJobs) {
          if (queuedJobs.isNotEmpty) {
            final payload = {
              'event': 'job_available',
              'queuedCount': queuedJobs.length,
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            };
            channel.sink.add(jsonEncode(payload));
          }
        },
        onError: (dynamic error) {
          stderr.writeln(
            '[WebSocket worker/jobs/stream.dart] DB stream error: $error',
          );
        },
        onDone: () {
          unawaited(channel.sink.close());
        },
      );

      final initialQueuedJobs = await db.buildJobDao.getQueuedJobs();
      if (initialQueuedJobs.isNotEmpty) {
        final payload = {
          'event': 'job_available',
          'queuedCount': initialQueuedJobs.length,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        };
        channel.sink.add(jsonEncode(payload));
      }

      channel.stream.listen(
        (dynamic message) {
          // incoming messages from worker
        },
        onDone: () {
          unawaited(dbSub?.cancel());
        },
        onError: (dynamic error) {
          unawaited(dbSub?.cancel());
        },
      );
    } catch (e) {
      unawaited(dbSub?.cancel());
      await channel.sink.close(WebSocketStatus.internalServerError);
    }
  });

  return handler(context);
}
