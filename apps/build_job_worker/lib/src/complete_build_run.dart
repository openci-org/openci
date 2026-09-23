import 'package:openci_shared/openci_shared.dart';

Future<void> completeBuildRun({
  required OpenCIApiService api,
  required String jobId,
  required String runId,
  required BuildJobStatus status,
}) async {
  final conclusion = switch (status) {
    BuildJobStatus.SUCCESS => 'success',
    BuildJobStatus.FAILURE => 'failure',
    BuildJobStatus.CANCELLED => 'cancelled',
    BuildJobStatus.SKIPPED => 'skipped',
    BuildJobStatus.TIMED_OUT => 'timed_out',
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
    final response = await api.updateRunStatus(jobId, runId, {
      'status': 'completed',
      'conclusion': conclusion,
    });
    isSuccessful = response.isSuccessful;
    statusCode = response.statusCode;
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      StateError('Failed to complete build run: ${error.runtimeType}.'),
      stackTrace,
    );
  }

  if (!isSuccessful) {
    throw StateError('Failed to complete build run: HTTP $statusCode.');
  }
}
