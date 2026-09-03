import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:openci_server/build_job/build_job_plan.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';
import 'package:uuid/uuid.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String taskId) async {
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

  final task = await db.webhookTaskDao.getWebhookTask(taskId);
  if (task == null) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'success': false, 'error': 'WebhookTask not found'},
    );
  }
  if (task.status == 'completed') {
    return _completionResponse(alreadyCompleted: true);
  }
  if (task.status != 'processing') {
    return _invalidStatusResponse(task.status);
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
    jobs = _parseJobs(payload);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'success': false, 'error': 'Invalid jobs: $e'},
    );
  }

  try {
    final result = await _completeTask(
      db: db,
      taskId: taskId,
      jobs: jobs,
    );
    return _completionResponse(
      jobIds: result.jobIds,
      alreadyCompleted: result.alreadyCompleted,
    );
  } on _WebhookTaskNotFound {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'success': false, 'error': 'WebhookTask not found'},
    );
  } on _InvalidWebhookTaskStatus catch (e) {
    return _invalidStatusResponse(e.status);
  } catch (e, s) {
    try {
      await db.webhookTaskDao.recordWebhookTaskFailure(
        taskId: taskId,
        errorMessage: '$e\n$s',
      );
    } catch (_) {}

    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to complete webhook task $taskId',
    );
  }
}

List<BuildJobPlan> _parseJobs(Map<String, dynamic> payload) {
  final rawJobs = payload['jobs'];
  if (rawJobs is! List) {
    throw const FormatException('jobs must be a list');
  }

  return rawJobs.indexed.map((entry) {
    final (index, rawJob) = entry;
    if (rawJob is! Map) {
      throw FormatException('jobs[$index] must be an object');
    }

    return BuildJobPlan.fromJson(Map<String, Object?>.from(rawJob));
  }).toList();
}

Future<_CompletionResult> _completeTask({
  required AppDatabase db,
  required String taskId,
  required List<BuildJobPlan> jobs,
}) async {
  var alreadyCompleted = false;
  final createdJobIds = <String>[];

  await db.transaction(() async {
    final now = DateTime.now().toUtc();
    final updatedCount =
        await (db.update(db.webhookTasks)..where(
              (task) =>
                  task.id.equals(taskId) & task.status.equals('processing'),
            ))
            .write(
              WebhookTasksCompanion(
                status: const Value('completed'),
                leaseUntil: const Value(null),
                nextRetryAt: const Value(null),
                errorMessage: const Value(null),
                updatedAt: Value(now),
              ),
            );

    if (updatedCount == 0) {
      final currentTask = await db.webhookTaskDao.getWebhookTask(taskId);
      if (currentTask == null) throw const _WebhookTaskNotFound();
      if (currentTask.status == 'completed') {
        alreadyCompleted = true;
        return;
      }
      throw _InvalidWebhookTaskStatus(currentTask.status);
    }

    for (final plan in jobs) {
      final id = const Uuid().v4();
      final job = plan.createBuildJob(id: id, timestamp: now);
      await db.buildJobDao.insertBuildJob(
        job.toDrift(installationId: plan.installationId),
      );
      createdJobIds.add(id);
    }
  });

  return _CompletionResult(
    jobIds: alreadyCompleted ? const [] : createdJobIds,
    alreadyCompleted: alreadyCompleted,
  );
}

Response _completionResponse({
  List<String> jobIds = const [],
  required bool alreadyCompleted,
}) {
  return Response.json(
    body: {
      'success': true,
      'jobs_created': jobIds.length,
      'job_ids': jobIds,
      'already_completed': alreadyCompleted,
    },
  );
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

class _CompletionResult {
  const _CompletionResult({
    required this.jobIds,
    required this.alreadyCompleted,
  });

  final List<String> jobIds;
  final bool alreadyCompleted;
}

class _WebhookTaskNotFound implements Exception {
  const _WebhookTaskNotFound();
}

class _InvalidWebhookTaskStatus implements Exception {
  const _InvalidWebhookTaskStatus(this.status);

  final String status;
}
