import 'package:firebase_functions/firebase_functions.dart';
import 'package:firebase_admin_sdk/messaging.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> handleBuildJobStatusChange(
  Request request,
  Firebase firebase,
) async {
  return handleRequest(request, (body) async {
    final buildJob = body['buildJob'] as Map<String, dynamic>?;
    final statusStr = body['status'] as String?;

    if (buildJob == null || statusStr == null) {
      return jsonResponse({
        'error': 'buildJob and status are required',
      }, status: 400);
    }

    final firestore = firebase.adminApp.firestore();
    final buildJobId = buildJob['id'] as String;

    // A. fail-fast マトリックスのキャンセル処理
    if (statusStr == 'FAILURE' &&
        buildJob['matrixFailFast'] != false &&
        buildJob['workflowRunId'] != null &&
        buildJob['matrixGroupKey'] != null) {
      final candidates = await firestore
          .collection(buildJobsCollection)
          .where('workflowRunId', WhereFilter.equal, buildJob['workflowRunId'])
          .where(
            'matrixGroupKey',
            WhereFilter.equal,
            buildJob['matrixGroupKey'],
          )
          .get();

      final batch = firestore.batch();
      final cancellableStatuses = {'WAITING', 'QUEUED', 'IN_PROGRESS'};
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final cancelledJobs = <Map<String, dynamic>>[];

      for (final doc in candidates.docs) {
        if (doc.id == buildJobId) continue;
        final currentStatus = doc.data()['status'] as String?;
        if (cancellableStatuses.contains(currentStatus)) {
          final updated = Map<String, dynamic>.from(doc.data());
          updated['status'] = 'CANCELLED';
          updated['completedAt'] = nowIso;
          updated['updatedAt'] = nowIso;

          batch.update(doc.ref, {
            FieldPath.from('status'): 'CANCELLED',
            FieldPath.from('completedAt'): nowIso,
            FieldPath.from('updatedAt'): nowIso,
          });
          cancelledJobs.add(updated);
        }
      }

      await batch.commit();

      // キャンセルされた他のマトリックスジョブの Check Run も完了させる
      for (final job in cancelledJobs) {
        await updateCheckRunInternal(
          job,
          'completed',
          'cancelled',
          firebase: firebase,
        );
      }
    }

    // B. 依存関係の解決
    Future<void> resolveDependencies(
      Map<String, dynamic> completedJob,
      String completedStatus,
    ) async {
      final workflowRunId = completedJob['workflowRunId'] as String?;
      final jobKey = completedJob['jobKey'] as String?;
      if (workflowRunId == null || jobKey == null) return;

      // 依存されている WAITING ジョブを探す
      final waitingSnap = await firestore
          .collection(buildJobsCollection)
          .where('workflowRunId', WhereFilter.equal, workflowRunId)
          .where('status', WhereFilter.equal, 'WAITING')
          .get();

      final isSuccess = completedStatus == 'SUCCESS';

      for (final doc in waitingSnap.docs) {
        final data = doc.data();
        final needs = data['needs'] as List<dynamic>? ?? [];
        if (!needs.contains(jobKey)) continue;

        if (!isSuccess) {
          // 失敗した場合は SKIPPED に変更し、再帰的にスキップさせる
          final nowIso = DateTime.now().toUtc().toIso8601String();
          final updated = Map<String, dynamic>.from(data);
          updated['status'] = 'SKIPPED';
          updated['completedAt'] = nowIso;
          updated['updatedAt'] = nowIso;

          await firestore.collection(buildJobsCollection).doc(doc.id).update({
            FieldPath.from('status'): 'SKIPPED',
            FieldPath.from('completedAt'): nowIso,
            FieldPath.from('updatedAt'): nowIso,
          });

          await updateCheckRunInternal(
            updated,
            'completed',
            'skipped',
            firebase: firebase,
          );
          await resolveDependencies(updated, 'SKIPPED');
          continue;
        }

        // 成功した場合は、resolvedNeeds にあるすべての依存関係が完了したかチェック
        final resolvedNeeds = data['resolvedNeeds'] as Map<String, dynamic>?;
        if (resolvedNeeds == null) continue;

        bool allSatisfied = true;
        for (final needBuildJobId in resolvedNeeds.values) {
          final needDoc = await firestore
              .collection(buildJobsCollection)
              .doc(needBuildJobId as String)
              .get();
          if (!needDoc.exists || needDoc.data()?['status'] != 'SUCCESS') {
            allSatisfied = false;
            break;
          }
        }

        if (allSatisfied) {
          await firestore.collection(buildJobsCollection).doc(doc.id).update({
            FieldPath.from('status'): 'QUEUED',
            FieldPath.from('updatedAt'): DateTime.now()
                .toUtc()
                .toIso8601String(),
          });
        }
      }
    }

    await resolveDependencies(buildJob, statusStr);

    // C. FCM 通知の送信
    final teamId = buildJob['teamId'] as String?;
    if (teamId != null && (statusStr == 'SUCCESS' || statusStr == 'FAILURE')) {
      final teamDoc = await firestore
          .collection(teamsCollection)
          .doc(teamId)
          .get();
      final members = teamDoc.data()?['members'] as List<dynamic>? ?? [];

      if (members.isNotEmpty) {
        final title = statusStr == 'SUCCESS'
            ? '✅ Build Succeeded'
            : '❌ Build Failed';

        // ログの最新行を取得して要約（エラー理由）を取得
        String failureSummary = 'Unknown error';
        if (statusStr == 'FAILURE' && buildJob['latestRunId'] != null) {
          final logsSnap = await firestore
              .collection(buildJobsCollection)
              .doc(buildJobId)
              .collection('runs')
              .doc(buildJob['latestRunId'] as String)
              .collection('logs')
              .orderBy('timestamp', descending: true)
              .limit(2)
              .get();

          if (logsSnap.docs.length >= 2) {
            failureSummary =
                logsSnap.docs[1].data()['message'] as String? ??
                'Unknown error';
          }
        }

        final bodyLines = [
          if (buildJob['workflowName'] != null)
            buildJob['workflowName'] as String,
          '${buildJob['repo']}${buildJob['branch'] != null ? ' (${buildJob['branch']})' : ''}',
          if (statusStr == 'FAILURE') failureSummary,
        ];

        final messaging = firebase.adminApp.messaging();

        for (final memberUid in members) {
          final userDoc = await firestore
              .collection(usersCollection)
              .doc(memberUid as String)
              .get();
          final userData = userDoc.data();
          if (userData == null) continue;

          final preference =
              userData['notificationPreference'] as String? ?? 'all';
          if (preference == 'none' ||
              (preference == 'successOnly' && statusStr != 'SUCCESS') ||
              (preference == 'failureOnly' && statusStr != 'FAILURE')) {
            continue;
          }

          final fcmTokens = userData['fcmTokens'] as List<dynamic>? ?? [];
          final invalidTokens = <String>{};

          for (final token in fcmTokens) {
            try {
              await messaging.send(
                TokenMessage(
                  token: token as String,
                  notification: Notification(
                    title: title,
                    body: bodyLines.join('\n'),
                  ),
                  data: {
                    'buildJobId': buildJobId,
                    'status': statusStr,
                    'owner': buildJob['owner'] as String? ?? '',
                    'repo': buildJob['repo'] as String? ?? '',
                    if (buildJob['branch'] != null)
                      'branch': buildJob['branch'] as String,
                    if (buildJob['workflowName'] != null)
                      'workflowName': buildJob['workflowName'] as String,
                  },
                  apns: ApnsConfig(
                    payload: ApnsPayload(
                      aps: Aps(sound: const ApsSoundName('default'), badge: 1),
                    ),
                  ),
                ),
              );
            } catch (e) {
              final errStr = e.toString();
              if (errStr.contains('not-registered') ||
                  errStr.contains('invalid-argument')) {
                invalidTokens.add(token);
              }
            }
          }

          if (invalidTokens.isNotEmpty) {
            final validTokens = fcmTokens
                .where((t) => !invalidTokens.contains(t))
                .toList();
            await firestore.collection(usersCollection).doc(memberUid).update({
              FieldPath.from('fcmTokens'): validTokens,
            });
          }
        }
      }
    }

    return jsonResponse({'success': true});
  });
}
