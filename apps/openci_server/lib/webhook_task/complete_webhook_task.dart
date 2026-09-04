import 'package:drift/drift.dart';
import 'package:openci_server/build_job/build_job_plan_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:uuid/uuid.dart';

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

    for (final plan in jobs) {
      final jobId = const Uuid().v4();
      await db.buildJobDao.insertBuildJob(
        plan.toDrift(id: jobId, timestamp: now),
      );
      createdJobIds.add(jobId);
    }
  });

  return CompleteWebhookTaskResult(
    jobIds: createdJobIds,
    alreadyCompleted: alreadyCompleted,
  );
}

class CompleteWebhookTaskResult {
  const CompleteWebhookTaskResult({
    required this.jobIds,
    required this.alreadyCompleted,
  });

  final List<String> jobIds;
  final bool alreadyCompleted;
}

class WebhookTaskNotFoundException implements Exception {
  const WebhookTaskNotFoundException();
}

class InvalidWebhookTaskStatusException implements Exception {
  const InvalidWebhookTaskStatusException(this.status);

  final String status;
}
