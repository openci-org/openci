import 'package:firebase_functions/firebase_functions.dart';

import 'cancel_build_job.dart';

void main(List<String> args) {
  runFunctions((firebase) {
    firebase.https.onCallWithData<CancelBuildJobRequest, Map<String, dynamic>>(
      name: 'cancelBuildJob',
      fromJson: CancelBuildJobRequest.fromJson,
      options: const CallableOptions(
        region: Region(SupportedRegion.asiaNortheast1),
        cors: Option(['*']),
      ),
      (request, response) => cancelBuildJob(request, firebase),
    );
  });
}
