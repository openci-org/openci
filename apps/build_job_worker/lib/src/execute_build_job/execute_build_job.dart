import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import '../checkout_repository.dart';
import '../complete_build_job.dart';
import '../complete_build_run.dart';
import '../complete_github_check_run.dart';
import '../config.dart';
import '../create_build_run.dart';
import '../fetch_job_secrets.dart';
import '../orchard/orchard_api_client.dart';
import '../orchard/prepare_vm.dart';
import '../resolve_github_installation_token.dart';
import '../run_workflow.dart';
import 'report_step_event.dart';
import 'report_step_log.dart';

Future<BuildJobStatus> executeBuildJob({
  required OpenCIApiService api,
  required OrchardApiClient orchardApi,
  required http.Client lokiClient,
  required Config config,
  required BuildJob job,
  required void Function(Object error, StackTrace stackTrace) onError,
  Duration finalizationTimeout = const Duration(seconds: 10),
}) async {
  if (job.status != BuildJobStatus.IN_PROGRESS) {
    throw ArgumentError.value(job.status, 'job.status', 'Job must be claimed.');
  }
  if (finalizationTimeout <= Duration.zero) {
    throw ArgumentError.value(
      finalizationTimeout,
      'finalizationTimeout',
      'Must be positive.',
    );
  }

  final runId =
      'run-${DateTime.now().microsecondsSinceEpoch}-'
      '${Random.secure().nextInt(1 << 32).toRadixString(16)}';
  final vmName = 'openci-vm-$runId';
  var status = BuildJobStatus.FAILURE;
  var runCreated = false;
  String? leaseId;
  final errors = <(Object, StackTrace)>[];
  final logErrors = <(Object, StackTrace)>[];

  final reportStepEvent = ReportStepEvent(
    lokiClient: lokiClient,
    lokiUrl: config.internalLokiUrl,
    jobId: job.id,
    runId: runId,
    onError: (error, stackTrace) => logErrors.add((error, stackTrace)),
  );
  final reportStepLog = ReportStepLog(
    lokiClient: lokiClient,
    lokiUrl: config.internalLokiUrl,
    jobId: job.id,
    runId: runId,
    onError: (error, stackTrace) => logErrors.add((error, stackTrace)),
  );

  try {
    await createBuildRun(api: api, jobId: job.id, runId: runId);
    runCreated = true;
    final token = await resolveGitHubInstallationToken(api: api, jobId: job.id);
    final startedAt = DateTime.now().toUtc();
    final vmStep = BuildStep(
      id: 'prepare_vm',
      runId: runId,
      name: 'Set up VM',
      status: BuildJobStatus.IN_PROGRESS,
      durationMs: 0,
      stepOrder: 0,
      createdAt: startedAt,
      updatedAt: startedAt,
    );
    await reportStepEvent.send(StepEvent(step: vmStep));
    await reportStepLog.send(
      stepId: vmStep.id,
      log: StepLog(
        message:
            'Creating VM from ${config.baseVmName} and waiting for it to start.',
      ),
    );
    final stopwatch = Stopwatch()..start();
    try {
      final lease = await prepareVm(
        api: orchardApi,
        baseVmName: config.baseVmName,
        vmName: vmName,
      );
      leaseId = lease.id.isNotEmpty ? lease.id : vmName;
    } finally {
      stopwatch.stop();
      await reportStepEvent.send(
        StepEvent(
          step: vmStep.copyWith(
            status: leaseId == null
                ? BuildJobStatus.FAILURE
                : BuildJobStatus.SUCCESS,
            durationMs: stopwatch.elapsedMilliseconds,
            updatedAt: DateTime.now().toUtc(),
          ),
        ),
      );
      await reportStepLog.send(
        stepId: vmStep.id,
        log: StepLog(
          message: leaseId == null ? 'VM setup failed.' : 'VM is ready.',
        ),
      );
    }

    final checkoutStartedAt = DateTime.now().toUtc();
    final checkoutStep = BuildStep(
      id: 'checkout',
      runId: runId,
      name: 'Checkout Repository',
      status: BuildJobStatus.IN_PROGRESS,
      durationMs: 0,
      stepOrder: 1,
      createdAt: checkoutStartedAt,
      updatedAt: checkoutStartedAt,
    );
    await reportStepEvent.send(StepEvent(step: checkoutStep));
    final checkoutStopwatch = Stopwatch()..start();
    var checkoutSucceeded = false;
    try {
      await checkoutRepository(
        api: orchardApi,
        lokiClient: lokiClient,
        lokiUrl: config.internalLokiUrl,
        vmName: vmName,
        job: job,
        token: token,
        runId: runId,
        onLogError: onError,
      );
      checkoutSucceeded = true;
    } finally {
      checkoutStopwatch.stop();
      await reportStepEvent.send(
        StepEvent(
          step: checkoutStep.copyWith(
            status: checkoutSucceeded
                ? BuildJobStatus.SUCCESS
                : BuildJobStatus.FAILURE,
            durationMs: checkoutStopwatch.elapsedMilliseconds,
            updatedAt: DateTime.now().toUtc(),
          ),
        ),
      );
    }
    final secretsContent = await fetchJobSecrets(api: api, jobId: job.id);
    final workflowStartedAt = DateTime.now().toUtc();
    final workflowStep = BuildStep(
      id: 'run_workflow',
      runId: runId,
      name: 'Run workflow',
      status: BuildJobStatus.IN_PROGRESS,
      durationMs: 0,
      stepOrder: 2,
      createdAt: workflowStartedAt,
      updatedAt: workflowStartedAt,
    );
    await reportStepEvent.send(StepEvent(step: workflowStep));
    final workflowStopwatch = Stopwatch()..start();
    try {
      final exitCode = await runWorkflow(
        api: orchardApi,
        lokiClient: lokiClient,
        lokiUrl: config.internalLokiUrl,
        vmLokiUrl: config.lokiUrl,
        vmName: vmName,
        job: job,
        runId: runId,
        secretsContent: secretsContent,
        onLogError: onError,
      );
      status = exitCode == 0 ? BuildJobStatus.SUCCESS : BuildJobStatus.FAILURE;
    } finally {
      workflowStopwatch.stop();
      await reportStepEvent.send(
        StepEvent(
          step: workflowStep.copyWith(
            status: status,
            durationMs: workflowStopwatch.elapsedMilliseconds,
            updatedAt: DateTime.now().toUtc(),
          ),
        ),
      );
    }
  } catch (error, stackTrace) {
    errors.add((error, stackTrace));
  } finally {
    final completedAt = DateTime.now().toUtc();
    final vmToDelete = leaseId;
    for (final action in <Future<void> Function()>[
      if (runCreated)
        () => completeBuildRun(
          api: api,
          jobId: job.id,
          runId: runId,
          status: status,
        ),
      () => completeBuildJob(
        api: api,
        jobId: job.id,
        status: status,
        completedAt: completedAt,
      ),
      () => completeGitHubCheckRun(api: api, jobId: job.id, status: status),
      if (vmToDelete != null) () => orchardApi.deleteLease(vmToDelete),
    ]) {
      try {
        await action().timeout(finalizationTimeout);
      } catch (error, stackTrace) {
        errors.add((error, stackTrace));
      }
    }
  }

  final reportErrorLog = ReportStepLog(
    lokiClient: lokiClient,
    lokiUrl: config.internalLokiUrl,
    jobId: job.id,
    runId: runId,
    onError: (error, stackTrace) => logErrors.add((error, stackTrace)),
    logTimeout: finalizationTimeout,
  );
  for (final (error, stackTrace) in errors) {
    await reportErrorLog.send(
      log: StepLog(message: 'Build job worker error: $error\n$stackTrace'),
      stream: 'stderr',
    );
  }
  for (final (error, stackTrace) in [...logErrors, ...errors]) {
    onError(error, stackTrace);
  }
  return status;
}
