import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> updateWorkerHeartbeat(
  Request request,
  Firebase firebase,
) async {
  return handleRequest(request, (body) async {
    final workerId = body['workerId'] as String?;
    if (workerId == null) {
      return jsonResponse({'error': 'workerId is required'}, status: 400);
    }

    final firestore = firebase.adminApp.firestore();
    final ref = firestore.collection(workerInstancesCollection).doc(workerId);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final isCreate = !snap.exists;

      final String createdAt;
      if (isCreate) {
        createdAt = nowIso;
      } else {
        final rawCreatedAt = snap.data()?['createdAt'];
        if (rawCreatedAt is Timestamp) {
          createdAt = rawCreatedAt.toDate().toUtc().toIso8601String();
        } else if (rawCreatedAt is String) {
          createdAt = rawCreatedAt;
        } else {
          createdAt = nowIso;
        }
      }

      final data = {
        'workerId': workerId,
        'version': body['version'],
        'platform': body['platform'],
        'hostname': body['hostname'],
        'pid': body['pid'],
        'status': body['status'],
        'lastSeenAt': nowIso,
        'currentBuildJobId': body['currentBuildJobId'],
        'currentRunId': body['currentRunId'],
        'consecutiveFailures': body['consecutiveFailures'] ?? 0,
        'lastError': body['lastError'],
        'updatedAt': nowIso,
        'createdAt': createdAt,
      };

      tx.set(ref, data);
    });

    return jsonResponse({
      'workerHeartbeat_upsert': {'id': workerId},
    });
  });
}
