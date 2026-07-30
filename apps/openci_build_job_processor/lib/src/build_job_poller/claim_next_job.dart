import 'package:openci_shared/openci_shared.dart';

Future<BuildJob?> claimNextJob({
  required OpenCiApiService apiService,
  required String runsOnPattern,
}) async {
  final response = await apiService.claimNextJob({
    'runsOnPattern': runsOnPattern,
  });

  if (!response.isSuccessful) {
    throw Exception(
      'Failed to claim next job: ${response.statusCode} - ${response.error}',
    );
  }

  final body = response.body;
  if (body == null) {
    throw Exception('Failed to claim next job: Response body is null');
  }

  final jobMap = body['job'] as Map<String, dynamic>?;
  if (jobMap == null) {
    return null;
  }

  return BuildJob.fromJson(jobMap);
}
