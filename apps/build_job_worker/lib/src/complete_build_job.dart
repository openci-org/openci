import 'package:openci_shared/openci_shared.dart';

import 'billing_attempt.dart';

Future<void> completeBuildJob({
  required OpenCIApiService api,
  required String jobId,
  required BuildJobStatus status,
  BillingAttempt? billingAttempt,
  required DateTime completedAt,
}) async {
  final statusName = switch (status) {
    BuildJobStatus.SUCCESS ||
    BuildJobStatus.FAILURE ||
    BuildJobStatus.CANCELLED ||
    BuildJobStatus.SKIPPED ||
    BuildJobStatus.TIMED_OUT => status.name,
    BuildJobStatus.WAITING ||
    BuildJobStatus.QUEUED ||
    BuildJobStatus.IN_PROGRESS => throw ArgumentError.value(
      status,
      'status',
      'A completed build job status is required.',
    ),
  };

  final bool isSuccessful;
  final int statusCode;
  try {
    final response = await api.completeJob(jobId, {
      ...?billingAttempt?.toJson(),
      'status': statusName,
      'completedAt': completedAt.toUtc().toIso8601String(),
    });
    isSuccessful = response.isSuccessful;
    statusCode = response.statusCode;
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      StateError('Failed to complete build job: ${error.runtimeType}.'),
      stackTrace,
    );
  }

  if (!isSuccessful) {
    throw StateError('Failed to complete build job: HTTP $statusCode.');
  }
}
