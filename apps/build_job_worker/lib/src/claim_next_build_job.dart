import 'package:openci_shared/openci_shared.dart';

Future<BuildJob?> claimNextBuildJob(
  OpenCIApiService api, {
  String? workerHost,
}) async {
  final response = await api.claimNextJob({'workerHost': ?workerHost});
  if (!response.isSuccessful || response.body == null) {
    throw StateError(
      'Failed to claim build job: HTTP ${response.statusCode} - ${response.error}',
    );
  }

  final body = response.body!;
  if (!body.containsKey('job')) {
    throw StateError('Invalid claim response: missing "job".');
  }

  final jobData = body['job'];
  if (jobData == null) {
    return null;
  }
  if (jobData is! Map<String, dynamic>) {
    throw StateError(
      'Invalid claim response: "job" must be an object or null.',
    );
  }

  final job = BuildJob.fromJson(jobData);
  if (workerHost != null && job.workerHost != workerHost) {
    throw StateError('Claimed job does not belong to this worker host.');
  }
  return job;
}
