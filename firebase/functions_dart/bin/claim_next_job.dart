import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> claimNextJob(Request request, Firebase firebase) async {
  return handleRequest(request, (body) async {
    final runsOnPattern = body['runsOnPattern'] as String?;
    final platform = (runsOnPattern ?? '').toLowerCase().contains('macos')
        ? 'macos'
        : 'ubuntu';

    final firestore = firebase.adminApp.firestore();

    final snapshot = await firestore
        .collection(buildJobsCollection)
        .where('status', WhereFilter.equal, 'QUEUED')
        .orderBy('createdAt')
        .limit(50)
        .get();

    final doc = snapshot.docs.firstWhereOrNull((candidate) {
      final runsOn = (candidate.data()['runsOn'] as String? ?? 'ubuntu-latest')
          .toLowerCase();
      return runsOn.contains(platform);
    });

    if (doc == null) {
      return jsonResponse({'job': null});
    }

    final jobData = await firestore.runTransaction((tx) async {
      final fresh = await tx.get(doc.ref);
      if (!fresh.exists || fresh.data()?['status'] != 'QUEUED') {
        return null;
      }

      final updatedData = Map<String, dynamic>.from(fresh.data()!);
      updatedData['status'] = 'IN_PROGRESS';
      updatedData['updatedAt'] = DateTime.now().toUtc().toIso8601String();

      tx.update(doc.ref, {
        FieldPath.from('status'): 'IN_PROGRESS',
        FieldPath.from('updatedAt'): DateTime.now().toUtc().toIso8601String(),
      });

      return updatedData;
    });

    return jsonResponse({'job': jobData});
  });
}
