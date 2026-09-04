import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';
import 'package:openci_server/webhook_task/complete_webhook_task.dart';
import 'package:openci_shared/openci_shared.dart';

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

    final List<BuildJobPlan> jobs;
    try {
      jobs = parseBuildJobPlans(payload);
    } on FormatException catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.message},
      );
    }

    final db = context.read<AppDatabase>();
    final result = await completeWebhookTask(
      db: db,
      taskId: taskId,
      jobs: jobs,
    );

    return Response.json(
      body: {
        'success': true,
        'jobs_created': result.jobIds.length,
        'job_ids': result.jobIds,
        'already_completed': result.alreadyCompleted,
      },
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
      logMessage: 'Failed to complete webhook task $taskId',
    );
  }
}
