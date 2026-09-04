import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';
import 'package:openci_server/webhook_task/fail_webhook_task.dart';
import 'package:openci_server/webhook_task/webhook_task_transition_exception.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String taskId) async {
  try {
    final uid = context.read<String?>();
    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }
    if (uid != 'system-job-processor') {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Internal API key required'},
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

    final String errorMessage;
    try {
      errorMessage = parseWebhookTaskErrorMessage(payload);
    } on FormatException catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.message},
      );
    }

    final db = context.read<AppDatabase>();
    final result = await failWebhookTask(
      db: db,
      taskId: taskId,
      errorMessage: errorMessage,
    );

    return Response.json(
      body: {'success': true, 'already_failed': result.alreadyFailed},
    );
  } on WebhookTaskNotFoundException {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'success': false, 'error': 'WebhookTask not found'},
    );
  } on InvalidWebhookTaskStatusException catch (e) {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {
        'success': false,
        'error': 'WebhookTask must be processing (current status: ${e.status})',
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to fail webhook task $taskId',
    );
  }
}
