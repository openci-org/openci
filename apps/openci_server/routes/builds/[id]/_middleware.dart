import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/worker_auth.dart';
import 'package:openci_server/database.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    final segments = context.request.uri.pathSegments;
    final isWebSocket = segments.isNotEmpty && segments.last == 'ws';

    if (segments.length < 2 || segments[0] != 'builds') {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid request path'},
      );
    }
    final id = segments[1];

    final driftJob = await db.buildJobDao.getBuildJob(id);
    if (driftJob == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Build job not found'},
      );
    }

    if (isWebSocket) {
      // WebSocket接続時は、トークン検証をハンドラ内で自前で行うため、
      // ミドルウェアでの認証・認可チェックをスキップし、driftJob を provide して通す。
      return handler(context.provide<DriftBuildJob>(() => driftJob));
    }

    // 通常のリクエストに対する認証・認可チェック
    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final teamId = driftJob.teamId;
    if (teamId == null) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final workerAuthError = verifyWorkerAuth(context, uid);
    if (workerAuthError != null) {
      final isMember = await db.teamDao.isTeamMember(uid, teamId);
      if (!isMember) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'success': false, 'error': 'Forbidden'},
        );
      }
    }

    return handler(context.provide<DriftBuildJob>(() => driftJob));
  };
}
