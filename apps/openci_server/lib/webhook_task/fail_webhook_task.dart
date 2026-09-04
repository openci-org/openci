import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/webhook_task_transition_exception.dart';

String parseWebhookTaskErrorMessage(Map<String, Object?> payload) {
  final errorMessage = payload['errorMessage'];
  if (errorMessage is! String || errorMessage.trim().isEmpty) {
    throw const FormatException('errorMessage must be a non-empty string');
  }
  return errorMessage.trim();
}

Future<FailWebhookTaskResult> failWebhookTask({
  required AppDatabase db,
  required String taskId,
  required String errorMessage,
}) async {
  var alreadyFailed = false;

  await db.transaction(() async {
    final updatedCount =
        await (db.update(db.webhookTasks)..where(
              (task) =>
                  task.id.equals(taskId) & task.status.equals('processing'),
            ))
            .write(
              WebhookTasksCompanion(
                status: const Value('failed'),
                errorMessage: Value(errorMessage),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );

    if (updatedCount > 0) {
      return;
    }

    final currentTask = await db.webhookTaskDao.getWebhookTask(taskId);
    if (currentTask == null) {
      throw const WebhookTaskNotFoundException();
    }
    if (currentTask.status == 'failed') {
      alreadyFailed = true;
      return;
    }
    throw InvalidWebhookTaskStatusException(currentTask.status);
  });

  return FailWebhookTaskResult(alreadyFailed: alreadyFailed);
}

class FailWebhookTaskResult {
  const FailWebhookTaskResult({required this.alreadyFailed});

  final bool alreadyFailed;
}
