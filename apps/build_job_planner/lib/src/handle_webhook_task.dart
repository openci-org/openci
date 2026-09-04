import 'package:openci_shared/openci_shared.dart';

import 'plan_webhook_task.dart';

Future<int> handleWebhookTask({
  required WebhookTask task,
  required OpenCiApiService api,
}) async {
  try {
    final plans = await planWebhookTask(task: task, api: api);
    final response = await api.completeWebhookTask(task.id, {
      'jobs': plans.map((plan) => plan.toJson()).toList(),
    });

    if (!response.isSuccessful || response.body?['success'] != true) {
      throw StateError(
        'Failed to complete webhook task ${task.id}: '
        'HTTP ${response.statusCode} - ${response.error}',
      );
    }

    final jobsCreated = response.body!['jobs_created'];
    if (jobsCreated is! int) {
      throw StateError(
        'Invalid completion response for webhook task ${task.id}: '
        'jobs_created must be an integer',
      );
    }

    return jobsCreated;
  } catch (error, stackTrace) {
    try {
      await _markWebhookTaskFailed(task: task, api: api, error: error);
    } catch (failureError) {
      Error.throwWithStackTrace(
        StateError(
          'Failed to handle webhook task ${task.id}: $error; '
          'also failed to mark it as failed: $failureError',
        ),
        stackTrace,
      );
    }

    Error.throwWithStackTrace(error, stackTrace);
  }
}

Future<void> _markWebhookTaskFailed({
  required WebhookTask task,
  required OpenCiApiService api,
  required Object error,
}) async {
  final response = await api.failWebhookTask(task.id, {
    'errorMessage': error.toString(),
  });
  if (!response.isSuccessful || response.body?['success'] != true) {
    throw StateError(
      'Failed to mark webhook task ${task.id} as failed: '
      'HTTP ${response.statusCode} - ${response.error}',
    );
  }
}
