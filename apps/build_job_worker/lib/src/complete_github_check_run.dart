import 'package:openci_shared/openci_shared.dart';

Future<void> completeGitHubCheckRun({
  required OpenCIApiService api,
  required String jobId,
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
    final response = await api.updateCheckRun(jobId, {
      'status': 'completed',
      'conclusion': conclusion,
    });
    isSuccessful = response.isSuccessful;
    statusCode = response.statusCode;
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      StateError('Failed to complete GitHub check run: ${error.runtimeType}.'),
      stackTrace,
    );
  }

  if (!isSuccessful) {
    throw StateError('Failed to complete GitHub check run: HTTP $statusCode.');
  }
}
