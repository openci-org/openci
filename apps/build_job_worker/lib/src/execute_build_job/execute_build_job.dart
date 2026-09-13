import 'dart:math';

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
import '../send_step_log_chunk.dart';

Future<BuildJobStatus> executeBuildJob({
  required OpenCiApiService api,
  required OrchardApiClient orchardApi,
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

  Future<void> reportVmLog(String message) async {
    try {
      await sendStepLogChunk(
        api: api,
        jobId: job.id,
        runId: runId,
        stepId: 'prepare_vm',
        lines: [message],
      ).timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      errors.add((error, stackTrace));
    }
  }

  try {
    await createBuildRun(api: api, jobId: job.id, runId: runId);
    runCreated = true;
    final token = await resolveGitHubInstallationToken(api: api, jobId: job.id);
    await reportVmLog(
      'Creating VM from ${config.baseVmName} and waiting for it to start.',
    );
    try {
      final lease = await prepareVm(
        api: orchardApi,
        baseVmName: config.baseVmName,
        vmName: vmName,
      );
      leaseId = lease.id.isNotEmpty ? lease.id : vmName;
    } finally {
      await reportVmLog(leaseId == null ? 'VM setup failed.' : 'VM is ready.');
    }

    await checkoutRepository(
      api: orchardApi,
      vmName: vmName,
      job: job,
      token: token,
    );
    final secretsContent = await fetchJobSecrets(api: api, jobId: job.id);
    final exitCode = await runWorkflow(
      api: orchardApi,
      vmName: vmName,
      job: job,
      runId: runId,
      secretsContent: secretsContent,
    );
    status = exitCode == 0 ? BuildJobStatus.SUCCESS : BuildJobStatus.FAILURE;
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

  // Error reporting must not interrupt the remaining completion/cleanup steps.
  for (final (error, stackTrace) in errors) {
    onError(error, stackTrace);
  }
  return status;
}
