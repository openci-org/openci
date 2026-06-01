import 'package:firebase_functions/firebase_functions.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> appendBuildLogs(Request request, Firebase firebase) async {
  return handleRequest(request, (body) async {
    final buildJobId = body['buildJobId'] as String?;
    final runId = body['runId'] as String?;
    final logs = body['logs'] as List<dynamic>?;

    if (buildJobId == null || runId == null || logs == null) {
      return jsonResponse({'error': 'buildJobId, runId, and logs are required'}, status: 400);
    }

    final firestore = firebase.adminApp.firestore();
    final batch = firestore.batch();

    final runRef = firestore
        .collection(buildJobsCollection)
        .doc(buildJobId)
        .collection('runs')
        .doc(runId);

    for (final logRaw in logs) {
      final log = logRaw as Map<String, dynamic>;
      final logId = log['id'] as String?;
      if (logId == null) continue;

      final logDocRef = runRef.collection('logs').doc(logId);
      batch.set(logDocRef, {
        'id': logId,
        'message': log['message'],
        'level': log['level'],
        'timestamp': log['timestamp'],
        if (log['stackTrace'] != null) 'stackTrace': log['stackTrace'],
      });
    }

    await batch.commit();

    return jsonResponse({'success': true});
  });
}
