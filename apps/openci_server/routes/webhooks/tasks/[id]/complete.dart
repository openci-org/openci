import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';
import 'package:openci_server/webhook_task/complete_webhook_task.dart';
import 'package:openci_server/webhook_task/webhook_task_transition_exception.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String taskId) async {
  try {
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
    Map<String, String>? environment;
    http.Client? client;
    try {
      environment = context.read<Map<String, String>>();
    } catch (_) {
      // Use the process environment when no override is provided.
    }
    try {
      client = context.read<http.Client>();
    } catch (_) {
      // Check creation owns its HTTP client when none is provided.
    }
    final result = await completeWebhookTask(
      db: db,
      taskId: taskId,
      jobs: jobs,
      environment: environment,
      client: client,
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
