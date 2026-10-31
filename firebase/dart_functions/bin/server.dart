import 'dart:io';

import 'package:firebase_functions/firebase_functions.dart';
import 'package:openci_dart_functions/process_webhook_task.dart';
import 'package:openci_dart_functions/src/planner_runtime.dart';

// SDK 0.6 uses this identifier as the Secret Manager name in its manifest.
// ignore: non_constant_identifier_names
final GITHUB_APP_PRIVATE_KEY = defineSecret('GITHUB_APP_PRIVATE_KEY');
final githubAppId = defineString('GITHUB_APP_ID');
final plannerServiceAccount = defineString(
  'OPENCI_PLANNER_SERVICE_ACCOUNT',
  ParamOptions(
    defaultValue: 'openci-planner@openci-b1b91.iam.gserviceaccount.com',
  ),
);
final githubApiBaseUrl = defineString(
  'GITHUB_API_BASE_URL',
  ParamOptions(defaultValue: 'https://api.github.com'),
);
final githubBaseUrl = defineString(
  'GITHUB_BASE_URL',
  ParamOptions(defaultValue: 'https://github.com'),
);

Future<void> main() async {
  await runFunctions((firebase) {
    firebase.https.onRequest(
      name: 'process-webhook-task',
      // SDK 0.6 supports defineSecret references in its manifest builder.
      // ignore: non_const_argument_for_const_parameter
      options: HttpsOptions(
        serviceAccount: ServiceAccount.param(plannerServiceAccount),
        region: Region(SupportedRegion.asiaNortheast1),
        invoker: Invoker.private(),
        memory: Memory(MemoryOption.mb128),
        cpu: Cpu(1),
        concurrency: Concurrency(1),
        minInstances: Instances(0),
        timeoutSeconds: TimeoutSeconds(480),
        secrets: [GITHUB_APP_PRIVATE_KEY],
      ),
      (request) => processWebhookTask(
        request,
        (taskId) => runPlanner(
          taskId,
          environment: Platform.environment,
          githubAppId: githubAppId.value(),
          githubPrivateKey: GITHUB_APP_PRIVATE_KEY.value(),
          githubApiBaseUrl: githubApiBaseUrl.value(),
          githubBaseUrl: githubBaseUrl.value(),
        ),
      ),
    );
  });
}
