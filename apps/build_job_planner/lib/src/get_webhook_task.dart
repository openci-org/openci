import 'package:logging/logging.dart';
import 'package:openci_shared/openci_shared.dart';

Future<WebhookTask?> getWebhookTask(OpenCiApiService api, Logger log) async {
  final response = await api.claimNextWebhookTask();
  if (!response.isSuccessful || response.body == null) {
    throw StateError(
      'Failed to claim webhook task: HTTP ${response.statusCode} - ${response.error}',
    );
  }

  final taskData = response.body!['task'] as Map<String, dynamic>?;
  if (taskData == null) {
    return null;
  }

  final task = WebhookTask.fromJson(taskData);
  log.info(
    'Claimed webhook task: ${task.id} (Event: ${task.eventType}, Delivery: ${task.deliveryId})',
  );
  return task;
}
