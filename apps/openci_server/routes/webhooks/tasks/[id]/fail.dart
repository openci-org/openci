import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String taskId) async {
  try {
    final db = context.read<AppDatabase>();
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

    final errorMessage = payload['errorMessage'];
    if (errorMessage is! String || errorMessage.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'errorMessage must be a non-empty string',
        },
      );
    }

    final currentTask = await db.webhookTaskDao.getWebhookTask(taskId);
    if (currentTask == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'WebhookTask not found'},
      );
    }
    if (currentTask.status == 'pending') {
      return _invalidStatusResponse(currentTask.status);
    }

    final updated = await db.webhookTaskDao.recordWebhookTaskFailure(
      taskId: taskId,
      errorMessage: errorMessage,
    );
    if (updated == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'WebhookTask not found'},
      );
    }
    if (updated.status == 'pending' || updated.status == 'processing') {
      return _invalidStatusResponse(updated.status);
    }

    return Response.json(
      body: {
        'success': true,
        'status': updated.status,
        'retry_count': updated.retryCount,
        'next_retry_at': updated.nextRetryAt?.toIso8601String(),
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to record webhook task failure $taskId',
    );
  }
}

Response _invalidStatusResponse(String status) {
  return Response.json(
    statusCode: HttpStatus.conflict,
    body: {
      'success': false,
      'error': 'WebhookTask must be processing (current status: $status)',
    },
  );
}
