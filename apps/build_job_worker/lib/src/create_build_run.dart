import 'package:openci_shared/openci_shared.dart';

Future<void> createBuildRun({
  required OpenCIApiService api,
  required String jobId,
  required String runId,
  String? billingAdmissionId,
  String? workerHost,
}) async {
  if (billingAdmissionId != null &&
      (billingAdmissionId.isEmpty ||
          workerHost == null ||
          workerHost.isEmpty)) {
    throw ArgumentError(
      'A paid run requires its admission and worker identity.',
    );
  }
  final bool isSuccessful;
  final int statusCode;
  try {
    final response = await api.createRun(jobId, {
      'id': runId,
      if (billingAdmissionId != null) ...{
        'billingAdmissionId': billingAdmissionId,
        'workerHost': workerHost,
      },
    });
    isSuccessful = response.isSuccessful;
    statusCode = response.statusCode;
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      StateError('Failed to create build run: ${error.runtimeType}.'),
      stackTrace,
    );
  }

  if (!isSuccessful) {
    throw StateError('Failed to create build run: HTTP $statusCode.');
  }
}
