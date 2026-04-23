import 'package:dio/dio.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';
import '../util/github_app.dart';
import '../util/github_urls.dart';
import '../util/logger.dart';

class CheckRunUpdateRequest {
  const CheckRunUpdateRequest({
    required this.buildJobId,
    required this.runStatus,
    this.conclusion,
  });

  factory CheckRunUpdateRequest.fromJson(Map<String, dynamic> json) {
    final buildJobId = json['buildJobId'] as String?;
    final runStatus = json['runStatus'] as String?;
    if (buildJobId == null || buildJobId.isEmpty) {
      throw InvalidArgumentError('Missing buildJobId');
    }
    if (runStatus == null || runStatus.isEmpty) {
      throw InvalidArgumentError('Missing runStatus');
    }
    return CheckRunUpdateRequest(
      buildJobId: buildJobId,
      runStatus: runStatus,
      conclusion: json['conclusion'] as String?,
    );
  }

  final String buildJobId;

  final String runStatus;

  final String? conclusion;
}

Future<Map<String, dynamic>> handleCheckRunUpdate(
  CallableRequest<CheckRunUpdateRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final buildJobId = request.data.buildJobId;
  final runStatus = request.data.runStatus;
  final conclusion = request.data.conclusion;

  final buildJobDoc = await firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .get();

  if (!buildJobDoc.exists) {
    throw NotFoundError('Build job not found');
  }

  final jobData = buildJobDoc.data()!;
  final checkRunId = jobData['checkRunId'];
  if (checkRunId == null) {
    return <String, dynamic>{'skipped': true, 'reason': 'No checkRunId'};
  }

  final owner = jobData['owner'] as String;
  final repo = jobData['repo'] as String;
  final installationToken = jobData['installationToken'] as String;
  final detailsUrl = buildDashboardRunUrl(buildJobId);
  final apiBaseUrl = (jobData['githubApiBaseUrl'] as String?) ??
      defaultGitHubApiBaseUrl;

  String ghStatus;
  String? ghConclusion;

  if (runStatus == 'in_progress') {
    ghStatus = 'in_progress';
  } else if (runStatus == 'completed') {
    ghStatus = 'completed';
    ghConclusion = conclusion;
  } else {
    return <String, dynamic>{
      'skipped': true,
      'reason': 'Unknown runStatus: $runStatus',
    };
  }

  try {
    final dio = Dio();
    try {
      final url =
          '$apiBaseUrl/repos/$owner/$repo/check-runs/$checkRunId';
      final body = <String, dynamic>{
        'status': ghStatus,
        'conclusion': ?ghConclusion,
        'details_url': detailsUrl,
      };

      final resp = await dio.patch<void>(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $installationToken',
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'OpenCI-Worker',
          },
        ),
      );

      logInfo(
        'Updated check run $checkRunId to $ghStatus (${ghConclusion ?? "n/a"}) - HTTP ${resp.statusCode}',
      );
    } finally {
      dio.close();
    }

    return <String, dynamic>{'success': true};
  } catch (e) {
    await logError('Failed to update check run $checkRunId', null, e);
    return <String, dynamic>{'success': false, 'error': e.toString()};
  }
}
