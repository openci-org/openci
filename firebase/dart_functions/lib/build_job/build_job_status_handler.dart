import 'package:dio/dio.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';
import '../secret_manager.dart';
import '../util/logger.dart';

// ---------------------------------------------------------------------------
// Request model
// ---------------------------------------------------------------------------

class BuildJobStatusChangeRequest {
  const BuildJobStatusChangeRequest({
    required this.buildJobId,
    required this.status,
  });

  factory BuildJobStatusChangeRequest.fromJson(Map<String, dynamic> json) {
    final buildJobId = json['buildJobId'] as String?;
    final status = json['status'] as String?;
    if (buildJobId == null || buildJobId.isEmpty) {
      throw InvalidArgumentError('Missing buildJobId');
    }
    if (status == null || status.isEmpty) {
      throw InvalidArgumentError('Missing status');
    }
    return BuildJobStatusChangeRequest(buildJobId: buildJobId, status: status);
  }

  final String buildJobId;
  final String status;
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

/// Called by the Worker CLI after updating a build job's status.
/// Replaces the Firestore trigger `onBuildJobStatusChange`.
///
/// Responsibilities:
/// 1. Resolve job dependencies (for terminal statuses)
/// 2. Generate AI failure summary (for failures)
/// 3. Send FCM push notifications (for success/failure)
Future<Map<String, dynamic>> handleBuildJobStatusChange(
  CallableRequest<BuildJobStatusChangeRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final buildJobId = request.data.buildJobId;
  final currentStatus = request.data.status;

  final buildJobDoc = await firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .get();

  if (!buildJobDoc.exists) {
    throw NotFoundError('Build job not found');
  }

  final jobData = buildJobDoc.data()!;

  // 1. Resolve dependencies for terminal statuses
  const terminalStatuses = [
    'success',
    'failure',
    'cancelled',
    'timed_out',
    'skipped',
  ];
  if (terminalStatuses.contains(currentStatus)) {
    await _resolveDependencies(jobData, currentStatus);
  }

  // 2. AI failure summary is now handled by a separate Cloud Function
  //    (generate-failure-summary), called directly by the Worker CLI.

  // 3. Send FCM notifications for success/failure
  if (currentStatus == 'success' || currentStatus == 'failure') {
    await _sendBuildNotifications(buildJobId, jobData, currentStatus);
  }

  return <String, dynamic>{'success': true};
}

// ---------------------------------------------------------------------------
// Dependency resolution
// ---------------------------------------------------------------------------

Future<void> _resolveDependencies(
  Map<String, dynamic> completedJobData,
  String completedStatus,
) async {
  final workflowRunId = completedJobData['workflowRunId'] as String?;
  final jobKey = completedJobData['jobKey'] as String?;

  if (workflowRunId == null || jobKey == null) return;

  final waitingJobs = await firestore
      .collection(buildJobsCollection)
      .where('workflowRunId', WhereFilter.equal, workflowRunId)
      .where('status', WhereFilter.equal, 'waiting')
      .get();

  if (waitingJobs.docs.isEmpty) return;

  final isSuccess = completedStatus == 'success';
  final now = DateTime.now().toUtc().toIso8601String();

  for (final doc in waitingJobs.docs) {
    final jobData = doc.data();
    final needs = (jobData['needs'] as List<dynamic>?)?.cast<String>();
    if (needs == null || !needs.contains(jobKey)) continue;

    if (!isSuccess) {
      // Dependency failed → skip this job
      await doc.ref.update({'status': 'skipped', 'updatedAt': now});
      logInfo(
        'Skipped job ${jobData['jobKey']} because dependency $jobKey $completedStatus',
      );

      // Cascade: skip children of this skipped job too
      await _resolveDependencies(jobData, 'skipped');
      continue;
    }

    // Dependency succeeded, check if ALL dependencies are now satisfied
    final resolvedNeeds = (jobData['resolvedNeeds'] as Map<String, dynamic>?)
        ?.cast<String, String>();
    if (resolvedNeeds == null) continue;

    var allSatisfied = true;
    for (final needBuildJobId in resolvedNeeds.values) {
      final needDoc = await firestore
          .collection(buildJobsCollection)
          .doc(needBuildJobId)
          .get();
      if (!needDoc.exists || needDoc.data()?['status'] != 'success') {
        allSatisfied = false;
        break;
      }
    }

    if (allSatisfied) {
      await doc.ref.update({'status': 'queued', 'updatedAt': now});
      logInfo('Queued job ${jobData['jobKey']} - all dependencies satisfied');
    }
  }
}

// ---------------------------------------------------------------------------
// FCM push notifications
// ---------------------------------------------------------------------------

Future<void> _sendBuildNotifications(
  String buildJobId,
  Map<String, dynamic> jobData,
  String currentStatus,
) async {
  final teamId = jobData['teamId'] as String?;
  if (teamId == null) return;

  final teamDoc = await firestore.collection(teamsCollection).doc(teamId).get();
  if (!teamDoc.exists) return;

  final members =
      (teamDoc.data()?['members'] as List<dynamic>?)?.cast<String>() ?? [];
  if (members.isEmpty) return;

  final owner = jobData['owner'] as String? ?? '';
  final repo = jobData['repo'] as String? ?? '';
  final branch = jobData['branch'] as String?;
  final workflowName = jobData['workflowName'] as String?;

  // Calculate duration
  var durationText = '';
  final createdAt = jobData['createdAt'] as String?;
  final completedAt = jobData['completedAt'] as String?;
  if (createdAt != null && completedAt != null) {
    try {
      final start = DateTime.parse(createdAt);
      final end = DateTime.parse(completedAt);
      final durationMs = end.difference(start).inMilliseconds;
      if (durationMs > 0) {
        final totalSeconds = durationMs ~/ 1000;
        final minutes = totalSeconds ~/ 60;
        final seconds = totalSeconds % 60;
        durationText = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
      }
    } catch (_) {}
  }

  final isSuccess = currentStatus == 'success';
  final title = isSuccess ? '✅ Build Succeeded' : '❌ Build Failed';

  final bodyLines = <String>[];
  if (workflowName != null) bodyLines.add(workflowName);
  bodyLines.add('$repo${branch != null ? ' ($branch)' : ''}');
  if (durationText.isNotEmpty) bodyLines.add('⏱ $durationText');

  // For failures, add last error message
  if (!isSuccess) {
    final latestRunId = jobData['latestRunId'] as String?;
    if (latestRunId != null) {
      final logsSnapshot = await firestore
          .collection(buildJobsCollection)
          .doc(buildJobId)
          .collection('runs')
          .doc(latestRunId)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .limit(2)
          .get();

      if (logsSnapshot.docs.length >= 2) {
        final failureLog = logsSnapshot.docs[1].data();
        bodyLines.add(failureLog['message'] as String? ?? 'Unknown error');
      } else {
        bodyLines.add('Unknown error');
      }
    }
  }

  final body = bodyLines.join('\n');

  // Collect FCM tokens
  final tokensToNotify = <String>[];
  for (final memberId in members) {
    final userDoc = await firestore
        .collection(usersCollection)
        .doc(memberId)
        .get();
    if (!userDoc.exists) continue;

    final userData = userDoc.data()!;
    final preference = userData['notificationPreference'] as String? ?? 'all';
    final fcmTokens =
        (userData['fcmTokens'] as List<dynamic>?)?.cast<String>() ?? [];
    if (fcmTokens.isEmpty) continue;

    if (preference == 'none') continue;
    if (preference == 'successOnly' && !isSuccess) continue;
    if (preference == 'failureOnly' && isSuccess) continue;

    tokensToNotify.addAll(fcmTokens);
  }

  if (tokensToNotify.isEmpty) return;

  // Send via FCM HTTP v1 API
  try {
    final accessToken = await _getAccessToken();
    final projectId = await _getProjectId();
    final dio = Dio();

    try {
      final invalidTokens = <String>[];

      for (final token in tokensToNotify) {
        try {
          await dio.post<void>(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
            data: {
              'message': {
                'token': token,
                'notification': {'title': title, 'body': body},
                'data': {
                  'buildJobId': buildJobId,
                  'status': currentStatus,
                  'owner': owner,
                  'repo': repo,
                  'branch': ?branch,
                  'workflowName': ?workflowName,
                  if (durationText.isNotEmpty) 'duration': durationText,
                },
                'apns': {
                  'payload': {
                    'aps': {'sound': 'default', 'badge': 1},
                  },
                },
              },
            },
            options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
          );
        } on DioException catch (e) {
          final errorMsg = e.response?.data?.toString() ?? '';
          if (errorMsg.contains('INVALID_ARGUMENT') ||
              errorMsg.contains('NOT_FOUND') ||
              errorMsg.contains('UNREGISTERED')) {
            invalidTokens.add(token);
          }
        }
      }

      logInfo(
        'Notifications sent to ${tokensToNotify.length - invalidTokens.length} devices',
      );

      // Clean up invalid tokens
      if (invalidTokens.isNotEmpty) {
        logInfo('Removing ${invalidTokens.length} invalid FCM tokens');
        for (final memberId in members) {
          final userDoc = await firestore
              .collection(usersCollection)
              .doc(memberId)
              .get();
          if (!userDoc.exists) continue;

          final userData = userDoc.data()!;
          final userTokens =
              (userData['fcmTokens'] as List<dynamic>?)?.cast<String>() ?? [];
          final validTokens = userTokens
              .where((t) => !invalidTokens.contains(t))
              .toList();

          if (validTokens.length != userTokens.length) {
            await userDoc.ref.update({'fcmTokens': validTokens});
          }
        }
      }
    } finally {
      dio.close();
    }
  } catch (e) {
    logError('Error sending notifications', null, e);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<String> _getAccessToken() async {
  final dio = Dio();
  try {
    final response = await dio.get<Map<String, dynamic>>(
      'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
      options: Options(headers: {'Metadata-Flavor': 'Google'}),
    );
    return response.data!['access_token'] as String;
  } finally {
    dio.close();
  }
}

Future<String> _getProjectId() async {
  final dio = Dio();
  try {
    final response = await dio.get<String>(
      'http://metadata.google.internal/computeMetadata/v1/project/project-id',
      options: Options(
        headers: {'Metadata-Flavor': 'Google'},
        responseType: ResponseType.plain,
      ),
    );
    return response.data!;
  } finally {
    dio.close();
  }
}

/// Cache for secret values to avoid repeated Secret Manager calls.
final _secretCache = <String, String>{};

Future<String> accessSecretCached(String name) async {
  if (_secretCache.containsKey(name)) return _secretCache[name]!;
  final value = await accessSecret(name);
  _secretCache[name] = value;
  return value;
}
