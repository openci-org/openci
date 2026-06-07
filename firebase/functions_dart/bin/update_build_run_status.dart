import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> updateBuildRunStatus(
  Request request,
  Firebase firebase,
) async {
  return handleRequest(request, (body) async {
    final buildJobId = body['buildJobId'] as String?;
    final runId = body['runId'] as String?;
    final status = body['status'] as String?;
    final conclusion = body['conclusion'] as String?;

    if (buildJobId == null || runId == null || status == null) {
      return jsonResponse({
        'error': 'buildJobId, runId, and status are required',
      }, status: 400);
    }

    final firestore = firebase.adminApp.firestore();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await firestore
        .collection(buildJobsCollection)
        .doc(buildJobId)
        .collection('runs')
        .doc(runId)
        .set({
          'status': status,
          'conclusion': conclusion,
          'updatedAt': nowIso,
        }, options: const SetOptions.merge());

    return jsonResponse({
      'buildRun_update': {'buildJobId': buildJobId, 'id': runId},
    });
  });
}
