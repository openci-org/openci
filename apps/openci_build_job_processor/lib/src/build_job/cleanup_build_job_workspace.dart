import 'dart:async';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/src/orchard/orchard_vm_service.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

class CleanupBuildJobWorkspace {
  CleanupBuildJobWorkspace({
    required OpenCiApiService apiService,
    required OrchardVmService orchardVmService,
  }) : _apiService = apiService,
       _orchardVmService = orchardVmService;

  final OpenCiApiService _apiService;
  final OrchardVmService _orchardVmService;
  final _log = Logger('CleanupBuildJobWorkspace');

  Future<void> call({
    required String jobId,
    required String runId,
    required BuildJobStatus status,
    String? vmName,
  }) async {
    await _updateJobFinalStatus(
      jobId: jobId,
      runId: runId,
      status: status,
      conclusion: status.name.toLowerCase(),
    );

    if (vmName != null) {
      _log.info('[$vmName] Cleaning up VM...');
      await _cleanupVm(vmName);
      _log.info('[$vmName] VM cleanup completed.');
    }
  }

  Future<void> _cleanupVm(String vmName) async {
    try {
      await _orchardVmService.cleanup(vmName);
    } catch (e, s) {
      _log.warning('[$vmName] Failed to delete Orchard VM: $e');
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
  }

  Future<void> _updateJobFinalStatus({
    required String jobId,
    required String runId,
    required BuildJobStatus status,
    required String conclusion,
  }) async {
    try {
      await _apiService
          .updateRunStatus(jobId, runId, {
            'status': 'completed',
            'conclusion': conclusion,
          })
          .timeout(const Duration(seconds: 10));
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    try {
      await _apiService
          .completeJob(jobId, {
            'status': status.name,
            'completedAt': DateTime.now().toUtc().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    try {
      await _apiService
          .updateCheckRun(jobId, {
            'status': 'completed',
            'conclusion': conclusion,
            'completedAt': DateTime.now().toUtc().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));
      await _apiService
          .handleBuildJobStatusChange(jobId, {'status': status.name})
          .timeout(const Duration(seconds: 10));
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
  }
}
