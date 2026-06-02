import 'package:firebase_functions/firebase_functions.dart';

import 'append_build_logs.dart';
import 'cancel_build_job.dart';
import 'claim_next_job.dart';
import 'complete_build_job.dart';
import 'create_build_run.dart';
import 'get_environment_variables.dart';
import 'get_secrets.dart';
import 'handle_build_job_status_change.dart';
import 'is_job_cancelled.dart';
import 'update_build_run_status.dart';
import 'update_check_run.dart';
import 'update_environment_variable.dart';
import 'update_worker_heartbeat.dart';
import 'resolve_installation_token.dart';
import 'get_secret_value.dart';
import 'worker_api_common.dart';

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

    firebase.https.onRequest(
      name: 'claimNextJob',
      options: workerOptions,
      (request) => claimNextJob(request, firebase),
    );

    firebase.https.onRequest(
      name: 'createBuildRun',
      options: workerOptions,
      (request) => createBuildRun(request, firebase),
    );

    firebase.https.onRequest(
      name: 'appendBuildLogs',
      options: workerOptions,
      (request) => appendBuildLogs(request, firebase),
    );

    firebase.https.onRequest(
      name: 'updateBuildRunStatus',
      options: workerOptions,
      (request) => updateBuildRunStatus(request, firebase),
    );

    firebase.https.onRequest(
      name: 'completeBuildJob',
      options: workerOptions,
      (request) => completeBuildJob(request, firebase),
    );

    firebase.https.onRequest(
      name: 'updateWorkerHeartbeat',
      options: workerOptions,
      (request) => updateWorkerHeartbeat(request, firebase),
    );

    firebase.https.onRequest(
      name: 'isJobCancelled',
      options: workerOptions,
      (request) => isJobCancelled(request, firebase),
    );

    firebase.https.onRequest(
      name: 'getEnvironmentVariables',
      options: workerOptions,
      (request) => getEnvironmentVariables(request, firebase),
    );

    firebase.https.onRequest(
      name: 'updateEnvironmentVariable',
      options: workerOptions,
      (request) => updateEnvironmentVariable(request, firebase),
    );

    firebase.https.onRequest(
      name: 'getSecrets',
      options: workerOptions,
      (request) => getSecrets(request, firebase),
    );

    firebase.https.onRequest(
      name: 'updateCheckRun',
      options: workerOptions,
      (request) => updateCheckRun(request, firebase),
    );

    firebase.https.onRequest(
      name: 'handleBuildJobStatusChange',
      options: workerOptions,
      (request) => handleBuildJobStatusChange(request, firebase),
    );

    firebase.https.onRequest(
      name: 'resolveInstallationToken',
      options: workerOptions,
      (request) => resolveInstallationToken(request, firebase),
    );

    firebase.https.onRequest(
      name: 'getSecretValue',
      options: workerOptions,
      (request) => getSecretValue(request, firebase),
    );
  });
}
