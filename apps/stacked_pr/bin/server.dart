import 'dart:io';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:stacked_pr_app/src/runtime.dart';

// Deployment settings are explicitly maintained in functions.yaml because the
// Dart SDK's default OS-only image does not contain the git executable.
Future<void> main() async {
  await runFunctions((firebase) {
    firebase.https.onRequest(
      name: 'stacked-pr-webhook',
      (request) => receiveWebhook(request, Platform.environment),
    );
    firebase.https.onRequest(
      name: 'stacked-pr-worker',
      (request) => processTask(request, (job) => runJob(job, Platform.environment)),
    );
  });
}
