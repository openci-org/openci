import 'dart:async';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/src/orchard/orchard_vm_service.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

class RunBuildJob {
  RunBuildJob({
    required OpenCiApiService apiService,
    required OrchardVmService orchardVmService,
  }) : _apiService = apiService,
       _orchardVmService = orchardVmService;

  final OpenCiApiService _apiService;
  final OrchardVmService _orchardVmService;
  final _log = Logger('RunBuildJob');

  Future<BuildJobStatus> call({
    required BuildJob job,
    required String vmName,
    String? runId,
  }) async {
    final targetScript = 'genuine_ci/${job.workflowFileName}';

    _log.info('[$vmName] Running Dart CI workflow: $targetScript');

    final commandScript = [
      'set -e',
      'export HOME=/Users/admin',
      'export PATH="/Users/admin/flutter/bin:/opt/homebrew/bin:\$PATH"',
      if (runId != null && runId.isNotEmpty)
        'export GENUINE_CI_RUN_ID="$runId"',
      'export GENUINE_CI_BUILD_JOB_ID="${job.id}"',
      'cd /tmp/workspace',
      'dart run $targetScript',
    ].join('\n');

    try {
      final exitCode = await _orchardVmService.executeCommandStreaming(
        containerName: vmName,
        command: ['/bin/sh', '-c', commandScript],
        onLog: (line) => _log.fine('[$vmName] $line'),
        isCancelled: () async => _isCancelled(job.id),
      );

      if (exitCode != 0) {
        _log.warning('[$vmName] Build workflow exited with code $exitCode');
        return BuildJobStatus.FAILURE;
      }
      return BuildJobStatus.SUCCESS;
    } catch (e, s) {
      _log.severe('[$vmName] Failed to execute build workflow: $e', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
      return BuildJobStatus.FAILURE;
    }
  }

  Future<bool> _isCancelled(String jobId) async {
    try {
      final res = await _apiService
          .getBuildJob(jobId)
          .timeout(const Duration(seconds: 10));
      if (res.isSuccessful) {
        final updatedJob = res.body;
        return updatedJob?['status'] == BuildJobStatus.CANCELLED.name ||
            updatedJob?['status'] == 'CANCELLING';
      }
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
    return false;
  }
}
