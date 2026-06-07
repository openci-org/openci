import 'package:firebase_functions/firebase_functions.dart';
import 'worker_api_common.dart';

Future<Response> updateCheckRun(Request request, Firebase firebase) async {
  return handleRequest(request, (body) async {
    final buildJob = body['buildJob'] as Map<String, dynamic>?;
    final runStatus = body['runStatus'] as String?;
    final conclusion = body['conclusion'] as String?;

    if (buildJob == null || runStatus == null) {
      return jsonResponse({
        'error': 'buildJob and runStatus are required',
      }, status: 400);
    }

    // Pass `firebase` so updateCheckRunInternal can pull checkRunId from
    // Firestore and mint a fresh installation token (the worker's BuildJob
    // model does not carry checkRunId/installationToken).
    await updateCheckRunInternal(
      buildJob,
      runStatus,
      conclusion,
      firebase: firebase,
    );
    return jsonResponse({'success': true});
  });
}
