import 'package:openci_shared/openci_shared.dart';

Future<BuildJob?> claimNextBuildJob(OpenCiApiService api) async {
  final response = await api.claimNextJob(const {});
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

  return BuildJob.fromJson(jobData);
}
