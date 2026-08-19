import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/webhook_task/webhook_task_mapper.dart';

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

    final driftTask = await db.webhookTaskDao.claimNextWebhookTask();
    if (driftTask == null) {
      return Response.json(body: {'task': null});
    }

    return Response.json(body: {'task': driftTask.toShared().toJson()});
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to claim next webhook task',
    );
  }
}
