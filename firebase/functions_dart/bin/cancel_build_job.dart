import 'package:firebase_functions/firebase_functions.dart';
import 'package:openci_shared/openci_shared.dart';

class CancelBuildJobRequest {
  CancelBuildJobRequest({required this.buildJobId});

  final String buildJobId;

  factory CancelBuildJobRequest.fromJson(Map<String, dynamic> json) {
    final buildJobId = json['buildJobId'];
    if (buildJobId == null || buildJobId is! String || buildJobId.isEmpty) {
      throw InvalidArgumentError(
        'buildJobId is required and must be a non-empty string',
      );
    }
    return CancelBuildJobRequest(buildJobId: buildJobId);
  }
}

Future<Map<String, dynamic>> cancelBuildJob(
  CallableRequest<CancelBuildJobRequest> request,
  Firebase firebase,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final buildJobId = request.data.buildJobId;
  final firestore = firebase.adminApp.firestore();

  final jobDoc = await firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .get();

  if (!jobDoc.exists) {
    throw NotFoundError('Build job not found');
  }

  final jobData = jobDoc.data()!;
  final job = BuildJob.fromJson(jobData);

  if (job.status != BuildJobStatus.QUEUED &&
      job.status != BuildJobStatus.IN_PROGRESS) {
    throw FailedPreconditionError(
      'Cannot cancel a build job with status \'${job.status.name}\'',
    );
  }

  final teamId = job.teamId;
  if (teamId == null || teamId.isEmpty) {
    throw FailedPreconditionError(
      'Build job is not associated with a team',
    );
  }

  final teamDoc = await firestore.collection(teamsCollection).doc(teamId).get();

  if (!teamDoc.exists) {
    throw NotFoundError('Team not found');
  }

  final teamData = teamDoc.data()!;
  final team = Team.fromJson(teamData);
  if (!team.members.contains(auth.uid)) {
    throw PermissionDeniedError(
      'You are not a member of this team',
    );
  }

  final now = DateTime.now().toUtc();
  final updatedJob = job.copyWith(
    status: BuildJobStatus.CANCELLED,
    completedAt: now,
    updatedAt: now,
  );
  await firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .set(updatedJob.toJson());

  logger.info('Build job $buildJobId cancelled by ${auth.uid} in team $teamId');

  return {'success': true};
}
