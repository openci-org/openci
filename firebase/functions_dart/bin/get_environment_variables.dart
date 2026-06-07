import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> getEnvironmentVariables(
  Request request,
  Firebase firebase,
) async {
  return handleRequest(request, (body) async {
    final teamId = body['teamId'] as String?;
    if (teamId == null) {
      return jsonResponse({'error': 'teamId is required'}, status: 400);
    }

    final firestore = firebase.adminApp.firestore();
    final snap = await firestore
        .collection(environmentVariablesCollection)
        .where('teamId', WhereFilter.equal, teamId)
        .orderBy('key')
        .get();

    final list = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    return jsonResponse({'environmentVariables': list});
  });
}
