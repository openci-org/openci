import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';

Future<Response> onRequest(RequestContext context) async {
  final queryParams = context.request.uri.queryParameters;
  final teamId = queryParams['teamId'];

  if (teamId == null || teamId.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'success': false, 'error': 'Missing teamId parameter'},
    );
  }

  final handler = webSocketHandler((channel, protocol) async {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid != null) {
      final isMember = await db.teamDao.isTeamMember(uid, teamId);
      if (!isMember) {
        await channel.sink.close(WebSocketStatus.normalClosure);
        return;
      }
    }

    StreamSubscription<List<DriftBuildJob>>? dbSub;

    try {
      dbSub = db.buildJobDao
          .watchBuildJobsForTeam(teamId: teamId)
          .listen(
            (driftJobs) {
              final jobs = driftJobs.map((j) => j.toShared()).toList();
              final commitGroups = groupBuildJobsToCommitGroups(jobs);
              final payload = commitGroups.map((g) => g.toJson()).toList();
              channel.sink.add(jsonEncode(payload));
            },
            onError: (dynamic error) {
              stderr.writeln(
                '[WebSocket commits/stream.dart] DB stream error: $error',
              );
            },
            onDone: () {
              unawaited(channel.sink.close());
            },
          );

      channel.stream.listen(
        (dynamic message) {
          // ping or client messages
        },
        onDone: () {
          unawaited(dbSub?.cancel());
        },
        onError: (dynamic error) {
          unawaited(dbSub?.cancel());
        },
      );
    } catch (e, s) {
      stderr.writeln(
        '[WebSocket commits/stream.dart] Failed to setup stream: $e\n$s',
      );
      unawaited(dbSub?.cancel());
      unawaited(channel.sink.close());
    }
  });

  return handler(context);
}
