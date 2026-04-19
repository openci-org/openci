import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/firestore_paths.dart';
import 'package:uuid/uuid.dart';

import '../firebase.dart';
import '../util/github_app.dart';
import '../util/logger.dart';
import '../util/team_auth.dart';

// ---------------------------------------------------------------------------
// Request models
// ---------------------------------------------------------------------------

class RetryBuildJobRequest {
  const RetryBuildJobRequest({required this.buildJobId});

  factory RetryBuildJobRequest.fromJson(Map<String, dynamic> json) {
    final buildJobId = json['buildJobId'] as String?;
    if (buildJobId == null || buildJobId.isEmpty) {
      throw InvalidArgumentError('Missing buildJobId');
    }
    return RetryBuildJobRequest(buildJobId: buildJobId);
  }

  final String buildJobId;
}

class RetryWorkflowRunRequest {
  const RetryWorkflowRunRequest({required this.workflowRunId});

  factory RetryWorkflowRunRequest.fromJson(Map<String, dynamic> json) {
    final workflowRunId = json['workflowRunId'] as String?;
    if (workflowRunId == null || workflowRunId.isEmpty) {
      throw InvalidArgumentError('Missing workflowRunId');
    }
    return RetryWorkflowRunRequest(workflowRunId: workflowRunId);
  }

  final String workflowRunId;
}

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> handleRetryBuildJob(
  CallableRequest<RetryBuildJobRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final callerUid = auth.uid;
  final buildJobId = request.data.buildJobId;

  final originalJobRef = firestore
      .collection(buildJobsCollection)
      .doc(buildJobId);
  final originalJobDoc = await originalJobRef.get();

  if (!originalJobDoc.exists) {
    throw NotFoundError('Build job not found');
  }

  final originalJob = originalJobDoc.data()!;

  // Verify team membership
  final teamId = originalJob['teamId'] as String?;
  if (teamId != null) {
    await verifyTeamMembership(auth: auth, teamId: teamId);
  }

  final newDocumentId = const Uuid().v4();
  final checkRunDetailsUrl = buildDashboardRunUrl(newDocumentId);

  // Get fresh GitHub installation token
  final installationId = originalJob['installationId'] as int?;
  String? installationToken;
  String? tokenExpiresAt;
  int? checkRunId = originalJob['checkRunId'] as int?;

  if (installationId != null) {
    try {
      final tokenData = await getInstallationToken(installationId);
      installationToken = tokenData['token'] as String;
      tokenExpiresAt = tokenData['expires_at'] as String;

      final commitSha = originalJob['commitSha'] as String?;
      if (commitSha != null) {
        final workflowName = originalJob['workflowName'] as String?;
        if (workflowName == null) {
          throw Exception('workflowName is missing on job $buildJobId');
        }
        checkRunId = null;
        checkRunId = await createCheckRun(
          token: installationToken,
          owner: originalJob['owner'] as String,
          repo: originalJob['repo'] as String,
          name: workflowName,
          headSha: commitSha,
          status: 'in_progress',
          detailsUrl: checkRunDetailsUrl,
        );
        if (checkRunId != null) {
          logInfo('Created new check run $checkRunId for retry');
        }
      }
    } catch (e) {
      logError('Failed to authenticate with GitHub for retry', null, e);
      throw InternalError('Failed to authenticate with GitHub');
    }
  }

  final now = DateTime.now().toUtc().toIso8601String();

  final newJobData = <String, dynamic>{
    'id': newDocumentId,
    'status': 'queued',
    'owner': originalJob['owner'],
    'repo': originalJob['repo'],
    'teamId': teamId,
    'workflowId': originalJob['workflowId'],
    'workflowFileName': originalJob['workflowFileName'],
    'workflowName': originalJob['workflowName'],
    'jobKey': originalJob['jobKey'],
    'workflowRunId': null,
    'needs': null,
    'resolvedNeeds': null,
    'installationId': installationId,
    'commitSha': originalJob['commitSha'],
    'pullRequestNumber': originalJob['pullRequestNumber'],
    'event': originalJob['event'],
    'action': originalJob['action'],
    'sender': originalJob['sender'],
    'repository': originalJob['repository'],
    'tagName': originalJob['tagName'],
    'installationToken': installationToken,
    'tokenExpiresAt': tokenExpiresAt,
    'checkRunId': checkRunId,
    'runsOn': originalJob['runsOn'],
    'branch': originalJob['branch'],
    'releaseName': originalJob['releaseName'],
    'runCount': 0,
    'latestRunId': null,
    'retriedFromBuildJobId': buildJobId,
    'createdAt': now,
    'updatedAt': now,
  };

  await firestore
      .collection(buildJobsCollection)
      .doc(newDocumentId)
      .set(newJobData);

  logInfo('Build job retried: $buildJobId -> $newDocumentId', {
    'callerUid': callerUid,
    'teamId': teamId,
    'owner': originalJob['owner'],
    'repo': originalJob['repo'],
  });

  return <String, dynamic>{'success': true, 'newBuildJobId': newDocumentId};
}

Future<Map<String, dynamic>> handleRetryWorkflowRun(
  CallableRequest<RetryWorkflowRunRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final callerUid = auth.uid;
  final workflowRunId = request.data.workflowRunId;

  final jobsSnapshot = await firestore
      .collection(buildJobsCollection)
      .where('workflowRunId', WhereFilter.equal, workflowRunId)
      .get();

  if (jobsSnapshot.docs.isEmpty) {
    throw NotFoundError('No jobs found for this workflow run');
  }

  final originalJobs = jobsSnapshot.docs.map((doc) => doc.data()).toList();

  final teamId = originalJobs[0]['teamId'] as String?;
  if (teamId != null) {
    await verifyTeamMembership(auth: auth, teamId: teamId);
  }

  final installationId = originalJobs[0]['installationId'] as int?;
  String? installationToken;
  String? tokenExpiresAt;

  if (installationId != null) {
    try {
      final tokenData = await getInstallationToken(installationId);
      installationToken = tokenData['token'] as String;
      tokenExpiresAt = tokenData['expires_at'] as String;
    } catch (e) {
      logError(
        'Failed to authenticate with GitHub for workflow retry',
        null,
        e,
      );
      throw InternalError('Failed to authenticate with GitHub');
    }
  }

  final newWorkflowRunId = const Uuid().v4();

  // First pass: assign new document IDs for each job
  final newJobDocIds = <String, String>{};
  for (final job in originalJobs) {
    final jobKey = job['jobKey'] as String?;
    if (jobKey != null) {
      newJobDocIds[jobKey] = const Uuid().v4();
    }
  }

  final createdJobIds = <String>[];
  final now = DateTime.now().toUtc().toIso8601String();

  for (final originalJob in originalJobs) {
    final jobKey = originalJob['jobKey'] as String?;
    final newDocumentId = jobKey != null
        ? newJobDocIds[jobKey]!
        : const Uuid().v4();
    final originalNeeds = (originalJob['needs'] as List<dynamic>?)
        ?.cast<String>();
    final hasNeeds = originalNeeds != null && originalNeeds.isNotEmpty;

    Map<String, String>? resolvedNeeds;
    if (hasNeeds) {
      resolvedNeeds = {};
      for (final needKey in originalNeeds) {
        if (newJobDocIds.containsKey(needKey)) {
          resolvedNeeds[needKey] = newJobDocIds[needKey]!;
        } else {
          logWarning(
            'Retry: Job "$jobKey" needs "$needKey" which doesn\'t exist in workflow',
          );
        }
      }
    }

    int? checkRunId;
    if (installationToken != null && originalJob['commitSha'] != null) {
      final workflowName = originalJob['workflowName'] as String?;
      if (workflowName == null) {
        logError('workflowName is missing on job $jobKey');
      } else {
        final multipleJobs = originalJobs.length > 1;
        final checkRunName = multipleJobs
            ? '$workflowName / $jobKey'
            : workflowName;
        final checkRunDetailsUrl = buildDashboardRunUrl(newDocumentId);

        checkRunId = await createCheckRun(
          token: installationToken,
          owner: originalJob['owner'] as String,
          repo: originalJob['repo'] as String,
          name: checkRunName,
          headSha: originalJob['commitSha'] as String,
          status: hasNeeds ? 'queued' : 'in_progress',
          detailsUrl: checkRunDetailsUrl,
        );
        if (checkRunId != null) {
          logInfo('Created new check run $checkRunId for retry $jobKey');
        }
      }
    }

    final newJobData = <String, dynamic>{
      'id': newDocumentId,
      'status': hasNeeds ? 'waiting' : 'queued',
      'owner': originalJob['owner'],
      'repo': originalJob['repo'],
      'teamId': originalJob['teamId'],
      'workflowId': originalJob['workflowId'],
      'workflowFileName': originalJob['workflowFileName'],
      'workflowName': originalJob['workflowName'],
      'jobKey': jobKey,
      'workflowRunId': newWorkflowRunId,
      'needs': originalNeeds,
      'resolvedNeeds': resolvedNeeds,
      'installationId': originalJob['installationId'],
      'commitSha': originalJob['commitSha'],
      'pullRequestNumber': originalJob['pullRequestNumber'],
      'event': originalJob['event'],
      'action': originalJob['action'],
      'sender': originalJob['sender'],
      'repository': originalJob['repository'],
      'tagName': originalJob['tagName'],
      'branch': originalJob['branch'],
      'releaseName': originalJob['releaseName'],
      'installationToken': installationToken,
      'tokenExpiresAt': tokenExpiresAt,
      'checkRunId': checkRunId,
      'runsOn': originalJob['runsOn'],
      'runCount': 0,
      'latestRunId': null,
      'retriedFromWorkflowRunId': workflowRunId,
      'createdAt': now,
      'updatedAt': now,
    };

    await firestore
        .collection(buildJobsCollection)
        .doc(newDocumentId)
        .set(newJobData);
    createdJobIds.add(newDocumentId);
  }

  logInfo(
    'Workflow run retried: $workflowRunId -> $newWorkflowRunId (${createdJobIds.length} jobs)',
    {
      'callerUid': callerUid,
      'teamId': teamId,
      'owner': originalJobs[0]['owner'],
      'repo': originalJobs[0]['repo'],
    },
  );

  return <String, dynamic>{
    'success': true,
    'newWorkflowRunId': newWorkflowRunId,
    'newBuildJobIds': createdJobIds,
  };
}
