import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> updateEnvironmentVariable(Request request, Firebase firebase) async {
  return handleRequest(request, (body) async {
    final id = body['id'] as String?;
    final value = body['value'] as String?;

    if (id == null || value == null) {
      return jsonResponse({'error': 'id and value are required'}, status: 400);
    }

    final firestore = firebase.adminApp.firestore();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await firestore.collection(environmentVariablesCollection).doc(id).update({
      FieldPath.from('value'): value,
      FieldPath.from('updatedAt'): nowIso,
    });

    return jsonResponse({
      'environmentVariable_update': {'id': id}
    });
  });
}
