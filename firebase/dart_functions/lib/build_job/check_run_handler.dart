import 'package:dio/dio.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';
import '../util/github_app.dart';
import '../util/logger.dart';

// ---------------------------------------------------------------------------
// Request model
// ---------------------------------------------------------------------------

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

  /// "in_progress" or "completed"
  final String runStatus;

  /// Only set when runStatus == "completed" (e.g. "success", "failure")
  final String? conclusion;
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

/// Called by the Worker CLI when a run is created (in_progress) or
/// completed. Patches the GitHub check run status accordingly.
/// Replaces the Firestore triggers `onRunCreated` and `onRunUpdated`.
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
    // No check run associated with this build job
    return <String, dynamic>{'skipped': true, 'reason': 'No checkRunId'};
  }

  final owner = jobData['owner'] as String;
  final repo = jobData['repo'] as String;
  final installationToken = jobData['installationToken'] as String;
  final detailsUrl = buildDashboardRunUrl(buildJobId);

  // Determine GitHub check run status & conclusion
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
          'https://api.github.com/repos/$owner/$repo/check-runs/$checkRunId';
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
    logError('Failed to update check run $checkRunId', null, e);
    return <String, dynamic>{'success': false, 'error': e.toString()};
  }
}
