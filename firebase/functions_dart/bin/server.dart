import 'package:firebase_functions/firebase_functions.dart';

class CancelBuildJobRequest {
  final String buildJobId;
  CancelBuildJobRequest({required this.buildJobId});

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

class CancelBuildJobResponse {
  final bool success;
  CancelBuildJobResponse({required this.success});

  Map<String, dynamic> toJson() => {'success': success};
}

void main(List<String> args) {
  runFunctions((firebase) {
    firebase.https.onCallWithData<CancelBuildJobRequest, Map<String, dynamic>>(
      name: 'cancelBuildJob',
      fromJson: CancelBuildJobRequest.fromJson,
      options: const CallableOptions(
        region: Region(SupportedRegion.asiaNortheast1),
        cors: Option(['*']),
      ),
      (request, response) async {
        final auth = request.auth;
        if (auth == null) {
          throw UnauthenticatedError('Unauthenticated');
        }

        final buildJobId = request.data.buildJobId;
        final firestore = firebase.adminApp.firestore();

        // 1. ビルドジョブの取得
        final jobDoc =
            await firestore.collection('build_jobs_v0').doc(buildJobId).get();

        if (!jobDoc.exists) {
          throw NotFoundError('Build job not found');
        }

        final jobData = jobDoc.data()!;
        final currentStatus = jobData['status'] as String?;

        // 2. ステータス検証 (QUEUED または IN_PROGRESS のみキャンセル可能)
        if (currentStatus != 'QUEUED' && currentStatus != 'IN_PROGRESS') {
          throw FailedPreconditionError(
            'Cannot cancel a build job with status \'$currentStatus\'',
          );
        }

        // 3. チームIDの検証
        final teamId = jobData['teamId'] as String?;
        if (teamId == null || teamId.isEmpty) {
          throw FailedPreconditionError(
            'Build job is not associated with a team',
          );
        }

        // 4. チームメンバーシップの検証
        final teamDoc =
            await firestore.collection('teams_v0').doc(teamId).get();

        if (!teamDoc.exists) {
          throw NotFoundError('Team not found');
        }

        final teamData = teamDoc.data()!;
        final List<dynamic> members =
            teamData['members'] as List<dynamic>? ?? [];
        if (!members.contains(auth.uid)) {
          throw PermissionDeniedError(
            'You are not a member of this team',
          );
        }

        // 5. ステータス更新 (日付更新は ISO8601 形式の文字列でおこなう)
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await firestore.collection('build_jobs_v0').doc(buildJobId).update({
          'status': 'CANCELLED',
          'completedAt': nowIso,
          'updatedAt': nowIso,
        });

        print('Build job $buildJobId cancelled by ${auth.uid} in team $teamId');

        return CancelBuildJobResponse(success: true).toJson();
      },
    );
  });
}
