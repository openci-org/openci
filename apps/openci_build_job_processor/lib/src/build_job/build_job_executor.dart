import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/src/build_job/cleanup_build_job_workspace.dart';
import 'package:openci_build_job_processor/src/build_job/prepare_build_job_workspace.dart';
import 'package:openci_build_job_processor/src/build_job/run_build_job.dart';
import 'package:openci_build_job_processor/src/orchard/orchard_api_client.dart';
import 'package:openci_build_job_processor/src/orchard/orchard_vm_service.dart';
import 'package:openci_build_job_processor/src/processor_config.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

class BuildJobExecutor {
  BuildJobExecutor({
    required PrepareBuildJobWorkspace prepareWorkspace,
    required RunBuildJob runBuildJob,
    required CleanupBuildJobWorkspace cleanupWorkspace,
  }) : _prepareWorkspace = prepareWorkspace,
       _runBuildJob = runBuildJob,
       _cleanupWorkspace = cleanupWorkspace;

  factory BuildJobExecutor.create({
    required OpenCiApiService apiService,
    required ProcessorConfig config,
    OrchardVmService? orchardVmService,
  }) {
    final vmService =
        orchardVmService ??
        OrchardVmService(
          apiClient: OrchardApiClient(
            baseUrl: config.orchardApiUrl,
            serviceAccountName: config.orchardServiceAccountName,
            serviceAccountToken: config.orchardServiceAccountToken,
          ),
        );

    return BuildJobExecutor(
      prepareWorkspace: PrepareBuildJobWorkspace(
        apiService: apiService,
        orchardVmService: vmService,
        config: config,
      ),
      runBuildJob: RunBuildJob(
        apiService: apiService,
        orchardVmService: vmService,
      ),
      cleanupWorkspace: CleanupBuildJobWorkspace(
        apiService: apiService,
        orchardVmService: vmService,
      ),
    );
  }

  final PrepareBuildJobWorkspace _prepareWorkspace;
  final RunBuildJob _runBuildJob;
  final CleanupBuildJobWorkspace _cleanupWorkspace;
  final _random = Random();
  final _log = Logger('BuildJobExecutor');

  String getVmName({required String jobId, required String runId}) {
    final shortJobId = jobId.substring(0, 8);
    final shortRunId = runId.substring(runId.length - 6);
    const baseName = 'openci-vm';
    return '$baseName-$shortJobId-$shortRunId';
  }

  String generateRunId() {
    final part1 = DateTime.now().millisecondsSinceEpoch;
    final part2 = _random.nextInt(1000000);
    return 'run-$part1-$part2';
  }

  Future<void> execute(BuildJob job) async {
    final runId = generateRunId();
    final vmName = getVmName(jobId: job.id, runId: runId);
    _log.info('[$vmName] Starting execution for job ${job.id} (run: $runId)');

    bool vmCreated = false;
    BuildJobStatus finalStatus = BuildJobStatus.FAILURE;

    try {
      await _prepareWorkspace(
        job: job,
        runId: runId,
        vmName: vmName,
        onVmCreated: () => vmCreated = true,
      );

      finalStatus = await _runBuildJob(job: job, vmName: vmName, runId: runId);
    } catch (e, s) {
      _log.severe('[$vmName] Critical exception during execution: $e', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
      finalStatus = BuildJobStatus.FAILURE;
    } finally {
      await _cleanupWorkspace(
        jobId: job.id,
        runId: runId,
        status: finalStatus,
        vmName: vmCreated ? vmName : null,
      );
    }
  }
}
