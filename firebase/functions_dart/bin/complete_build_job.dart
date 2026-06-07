import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> completeBuildJob(Request request, Firebase firebase) async {
  return handleRequest(request, (body) async {
    final id = body['id'] as String?;
    final status = body['status'] as String?;
    final completedAt = body['completedAt'] as String?;

    if (id == null || status == null) {
      return jsonResponse({'error': 'id and status are required'}, status: 400);
    }

    final firestore = firebase.adminApp.firestore();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await firestore.collection(buildJobsCollection).doc(id).update({
      FieldPath.from('status'): status,
      FieldPath.from('completedAt'): completedAt ?? nowIso,
      FieldPath.from('updatedAt'): nowIso,
    });

    return jsonResponse({
      'buildJob_update': {'id': id},
    });
  });
}
