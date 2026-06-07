import 'package:firebase_functions/firebase_functions.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> isJobCancelled(Request request, Firebase firebase) async {
  return handleRequest(request, (body) async {
    final buildJobId = body['buildJobId'] as String?;
    if (buildJobId == null) {
      return jsonResponse({'error': 'buildJobId is required'}, status: 400);
    }

    final firestore = firebase.adminApp.firestore();
    final doc = await firestore
        .collection(buildJobsCollection)
        .doc(buildJobId)
        .get();

    if (!doc.exists) {
      return jsonResponse({'cancelled': false});
    }

    final status = doc.data()?['status'] as String?;
    return jsonResponse({'cancelled': status == 'CANCELLED'});
  });
}
