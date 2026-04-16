import 'package:firebase_functions/firebase_functions.dart';
import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';
import '../util/logger.dart';

/// Request model for `cancelBuildJob`.
class CancelBuildJobRequest {
  const CancelBuildJobRequest({required this.buildJobId});

  factory CancelBuildJobRequest.fromJson(Map<String, dynamic> json) {
    final buildJobId = json['buildJobId'] as String?;
    if (buildJobId == null || buildJobId.isEmpty) {
      throw InvalidArgumentError('Missing buildJobId');
    }
    return CancelBuildJobRequest(buildJobId: buildJobId);
  }

  final String buildJobId;
}

/// Handler for the `cancelBuildJob` callable function.
///
/// Cancels a queued or in-progress build job.
Future<Map<String, dynamic>> handleCancelBuildJob(
  CallableRequest<CancelBuildJobRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final callerUid = auth.uid;
  final buildJobId = request.data.buildJobId;

  final jobRef = firestore.collection(buildJobsCollection).doc(buildJobId);
  final jobDoc = await jobRef.get();

  if (!jobDoc.exists) {
    throw NotFoundError('Build job not found');
  }

  final jobData = jobDoc.data()!;
  final currentStatus = jobData['status'] as String?;

  // Only queued or in_progress jobs can be cancelled
  if (currentStatus != 'queued' && currentStatus != 'in_progress') {
    throw FailedPreconditionError(
      "Cannot cancel a build job with status '$currentStatus'",
    );
  }

  // Verify team membership
  final teamId = jobData['teamId'] as String?;
  if (teamId != null) {
    final teamDoc = await firestore
        .collection(teamsCollection)
        .doc(teamId)
        .get();

    if (!teamDoc.exists) {
      throw NotFoundError('Team not found');
    }

    final teamData = teamDoc.data()!;
    final members =
        (teamData['members'] as List<dynamic>?)?.cast<String>() ?? [];

    if (!members.contains(callerUid)) {
      throw PermissionDeniedError('You are not a member of this team');
    }
  }

  // Update build job status to cancelled
  await jobRef.update({'status': 'cancelled'});

  logInfo('Build job cancelled: $buildJobId', {
    'callerUid': callerUid,
    'teamId': teamId,
    'previousStatus': currentStatus,
  });

  return <String, dynamic>{'success': true};
}
