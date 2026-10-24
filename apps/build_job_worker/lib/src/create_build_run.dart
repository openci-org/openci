import 'package:openci_shared/openci_shared.dart';

Future<int> createBuildRun({
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
  final Map<String, dynamic>? body;
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
    body = response.body;
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      StateError('Failed to create build run: ${error.runtimeType}.'),
      stackTrace,
    );
  }

  if (!isSuccessful) {
    throw StateError('Failed to create build run: HTTP $statusCode.');
  }

  final runNumber = body?['runNumber'];
  if (body?['success'] != true || runNumber is! int || runNumber <= 0) {
    throw StateError(
      'Invalid build run response: '
      '"success" must be true and "runNumber" must be a positive integer.',
    );
  }
  return runNumber;
}
