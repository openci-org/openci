import 'package:openci_shared/openci_shared.dart';

Future<void> createBuildRun({
  required OpenCIApiService api,
  required String jobId,
  required String runId,
}) async {
  final bool isSuccessful;
  final int statusCode;
  try {
    final response = await api.createRun(jobId, {'id': runId});
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
