import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> createBuildRun(Request request, Firebase firebase) async {
  return handleRequest(request, (body) async {
    final buildJobId = body['buildJobId'] as String?;
    final runId = body['id'] as String?;

    if (buildJobId == null || runId == null) {
      return jsonResponse({'error': 'buildJobId and id are required'}, status: 400);
    }

    final firestore = firebase.adminApp.firestore();

    await firestore.runTransaction((tx) async {
      final jobRef = firestore.collection(buildJobsCollection).doc(buildJobId);
      final runRef = jobRef.collection('runs').doc(runId);

      final nowIso = DateTime.now().toUtc().toIso8601String();

      tx.set(
        runRef,
        {
          'id': runId,
          'status': 'in_progress',
          'createdAt': nowIso,
          'updatedAt': nowIso,
        },
        options: const SetOptions.merge(),
      );

      tx.update(jobRef, {
        FieldPath.from('latestRunId'): runId,
        FieldPath.from('runCount'): FieldValue.increment(1),
        FieldPath.from('updatedAt'): nowIso,
      });
    });

    return jsonResponse({
      'buildRun_upsert': {'buildJobId': buildJobId, 'id': runId},
      'buildJob_update': {'id': buildJobId}
    });
  });
}
