import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:gcp_secret_manager/gcp_secret_manager.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:collection/collection.dart';
import 'worker_api_common.dart';

Future<Response> getSecretValue(Request request, Firebase firebase) async {
  return handleRequest(request, (body) async {
    final teamId = body['teamId'] as String?;
    final name = body['name'] as String?;
    if (teamId == null || name == null) {
      return jsonResponse({'error': 'teamId and name are required'}, status: 400);
    }

    final firestore = firebase.adminApp.firestore();
    final snap = await firestore
        .collection(secretsCollection)
        .where('teamId', WhereFilter.equal, teamId)
        .get();

    final doc = snap.docs.firstWhereOrNull((d) => d.data()['name'] == name);
    if (doc == null) {
      return jsonResponse({'error': 'Secret not found'}, status: 404);
    }

    final pathToSecret = doc.data()['pathToSecret'] as String?;
    if (pathToSecret == null || pathToSecret.isEmpty) {
      return jsonResponse({'error': 'pathToSecret is not configured'}, status: 400);
    }

    try {
      final value = await GcpSecretManager.fetchSecretValue(pathToSecret);
      return jsonResponse({'value': value});
    } catch (e) {
      return jsonResponse({'error': 'Failed to fetch secret value', 'details': e.toString()}, status: 500);
    }
  });
}
