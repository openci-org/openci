import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/build_job/build_job_plan_mapper.dart';
import 'package:openci_server/build_job/create_queued_check_run.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_repository_url.dart';
import 'package:openci_server/webhook_task/webhook_task_transition_exception.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:uuid/uuid.dart';

part 'complete_webhook_task.freezed.dart';

List<BuildJobPlan> parseBuildJobPlans(Map<String, Object?> payload) {
  final rawJobs = payload['jobs'];
  if (rawJobs is! List) {
    throw const FormatException('jobs must be a list');
  }

  return rawJobs.indexed.map((entry) {
    final (index, rawJob) = entry;
    if (rawJob is! Map) {
      throw FormatException('jobs[$index] must be an object');
    }

    try {
      return BuildJobPlan.fromJson(Map<String, Object?>.from(rawJob));
    } catch (e) {
      throw FormatException('jobs[$index] is invalid: $e');
    }
  }).toList();
}

Future<CompleteWebhookTaskResult> completeWebhookTask({
  required AppDatabase db,
  required String taskId,
  required List<BuildJobPlan> jobs,
  Map<String, String>? environment,
  http.Client? client,
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
                errorMessage: const Value(null),
                updatedAt: Value(now),
              ),
            );

    if (updatedCount == 0) {
      final currentTask = await db.webhookTaskDao.getWebhookTask(taskId);
      if (currentTask == null) {
        throw const WebhookTaskNotFoundException();
      }
      if (currentTask.status == 'completed') {
        alreadyCompleted = true;
        return;
      }
      throw InvalidWebhookTaskStatusException(currentTask.status);
    }

    if (jobs.isEmpty) return;

    final createdJobs = <DriftBuildJob>[];
    final githubBaseUrl = githubRepositoryBaseUrl(environment: environment);
    for (final plan in jobs) {
      final jobId = const Uuid().v4();
      final job = plan.toDrift(
        id: jobId,
        timestamp: now,
        githubBaseUrl: githubBaseUrl,
      );
      await db.buildJobDao.insertBuildJob(job);
      createdJobs.add(job);
      createdJobIds.add(jobId);
    }

    const concurrentChecks = 4;
    for (
      var offset = 0;
      offset < createdJobs.length;
      offset += concurrentChecks
    ) {
      await Future.wait(
        createdJobs
            .skip(offset)
            .take(concurrentChecks)
            .map(
              (job) => createQueuedCheckRun(
                db: db,
                job: job,
                environment: environment,
                client: client,
              ),
            ),
      );
    }
  });

  return CompleteWebhookTaskResult(
    jobIds: createdJobIds,
    alreadyCompleted: alreadyCompleted,
  );
}

@freezed
abstract class CompleteWebhookTaskResult with _$CompleteWebhookTaskResult {
  const factory CompleteWebhookTaskResult({
    required List<String> jobIds,
    required bool alreadyCompleted,
  }) = _CompleteWebhookTaskResult;
}
