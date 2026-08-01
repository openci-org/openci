import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';

FutureOr<Response> onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final Map<String, dynamic> payload;
    try {
      payload = await context.jsonBody();
    } on BadRequestException catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.message},
      );
    }

    final workerId = payload['workerId'] as String?;
    if (workerId == null || workerId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'workerId is required'},
      );
    }

    final now = DateTime.now().toUtc();
    final driftHeartbeat = DriftWorkerHeartbeat(
      id: workerId,
      version: payload['version'] as String?,
      platform: payload['platform'] as String?,
      status: payload['status'] as String?,
      lastSeenAt: now,
    );

    await db.workerHeartbeatDao.upsertHeartbeat(driftHeartbeat);

    return Response.json(
      body: {
        'success': true,
        'workerHeartbeat_upsert': {'id': workerId},
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to update worker heartbeat',
    );
  }
}
