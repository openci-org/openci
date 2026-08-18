import 'dart:async';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/src/orchard/orchard_vm_service.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

class RunBuildJobScript {
  RunBuildJobScript({
    required OpenCiApiService apiService,
    required OrchardVmService orchardVmService,
  }) : _apiService = apiService,
       _orchardVmService = orchardVmService;

  final OpenCiApiService _apiService;
  final OrchardVmService _orchardVmService;
  final _log = Logger('RunBuildJobScript');

  Future<BuildJobStatus> call({
    required BuildJob job,
    required String vmName,
  }) async {
    _log.info('[$vmName] Fetching build script for job ${job.id}...');
    final buildScript = await fetchBuildScript(job.id);

    _log.info('[$vmName] Dispatching command execution to VM: $buildScript');
    try {
      final exitCode = await _orchardVmService.executeCommandStreaming(
        containerName: vmName,
        command: ['/bin/sh', '-c', 'cd /tmp/workspace && $buildScript'],
        onLog: (line) => _log.fine('[$vmName] $line'),
        isCancelled: () async => _isCancelled(job.id),
      );

      if (exitCode != 0) {
        _log.warning('[$vmName] Build script exited with code $exitCode');
        return BuildJobStatus.FAILURE;
      }
      return BuildJobStatus.SUCCESS;
    } catch (e) {
      _log.severe('[$vmName] Failed to execute script: $e');
      return BuildJobStatus.FAILURE;
    }
  }

  Future<String> fetchBuildScript(String buildJobId) async {
    final response = await _apiService.getJobBuildScript(buildJobId);
    if (!response.isSuccessful) {
      throw StateError(
        'Failed to fetch build script for job $buildJobId: ${response.statusCode} - ${response.error}',
      );
    }
    final script = response.body?['script'] as String?;
    if (script == null || script.trim().isEmpty) {
      throw StateError('Build script is empty for job $buildJobId');
    }
    return script.trim();
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
