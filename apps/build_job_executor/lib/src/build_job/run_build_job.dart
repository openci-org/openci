import 'dart:async';

import 'package:build_job_executor/src/loki/loki_logger.dart';
import 'package:build_job_executor/src/orchard/orchard_vm_service.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

class RunBuildJob {
  RunBuildJob({
    required OpenCiApiService apiService,
    required OrchardVmService orchardVmService,
    this.lokiUrl = 'http://192.168.64.1:3100',
    LokiLogger? lokiLogger,
  }) : _apiService = apiService,
       _orchardVmService = orchardVmService,
       _lokiLogger = lokiLogger ?? LokiLogger(lokiUrl: 'http://loki:3100');

  final OpenCiApiService _apiService;
  final OrchardVmService _orchardVmService;
  final String lokiUrl;
  final LokiLogger _lokiLogger;
  final _log = Logger('RunBuildJob');

  Future<BuildJobStatus> call({
    required BuildJob job,
    required String vmName,
    String? runId,
  }) async {
    final targetScript = 'genuine_ci/${job.workflowFileName}';
    const workflowStepId = 'run_workflow';
    final stopwatch = Stopwatch()..start();

    _log.info('[$vmName] Running Dart CI workflow: $targetScript');

    if (runId != null && runId.isNotEmpty) {
      await _lokiLogger.pushStepEvent(
        runId: runId,
        jobId: job.id,
        stepId: workflowStepId,
        name: 'Run Dart CI Workflow (${job.workflowName})',
        status: BuildJobStatus.IN_PROGRESS.name,
        stepOrder: 2,
      );
    }

    final commandScript = [
      'set -e',
      'export HOME=/Users/admin',
      'export FLUTTER_ROOT="/Users/admin/fvm/default"',
      'export PATH="/Users/admin/fvm/default/bin:/Users/admin/.pub-cache/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH"',
      if (runId != null && runId.isNotEmpty)
        'export GENUINE_CI_RUN_ID="$runId"',
      'export GENUINE_CI_BUILD_JOB_ID="${job.id}"',
      'export LOKI_URL="$lokiUrl"',
      'cd /tmp/workspace',
      'flutter pub get',
      'flutter pub run $targetScript',
    ].join('\n');

    try {
      await _orchardVmService.writeFile(
        vmName,
        '/tmp/run_workflow.sh',
        commandScript,
        mode: '+x',
      );

      final exitCode = await _orchardVmService.executeCommandStreaming(
        containerName: vmName,
        command: ['/bin/sh', '/tmp/run_workflow.sh'],
        onLog: (line) {
          _log.fine('[$vmName] $line');
          if (runId != null && runId.isNotEmpty && !_isNoiseLine(line)) {
            _lokiLogger.pushLog(
              runId: runId,
              jobId: job.id,
              stepId: workflowStepId,
              message: line,
            );
          }
        },
        isCancelled: () async => _isCancelled(job.id),
      );

      if (exitCode != 0) {
        _log.warning('[$vmName] Build workflow exited with code $exitCode');
        if (runId != null && runId.isNotEmpty) {
          await _lokiLogger.pushLog(
            runId: runId,
            jobId: job.id,
            stepId: workflowStepId,
            message: 'Build workflow exited with code $exitCode',
            stream: 'stderr',
          );
          await _lokiLogger.pushStepEvent(
            runId: runId,
            jobId: job.id,
            stepId: workflowStepId,
            name: 'Run Dart CI Workflow (${job.workflowName})',
            status: BuildJobStatus.FAILURE.name,
            stepOrder: 2,
            durationMs: stopwatch.elapsedMilliseconds,
          );
        }
        return BuildJobStatus.FAILURE;
      }

      if (runId != null && runId.isNotEmpty) {
        await _lokiLogger.pushStepEvent(
          runId: runId,
          jobId: job.id,
          stepId: workflowStepId,
          name: 'Run Dart CI Workflow (${job.workflowName})',
          status: BuildJobStatus.SUCCESS.name,
          stepOrder: 2,
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }
      return BuildJobStatus.SUCCESS;
    } catch (e, s) {
      _log.severe('[$vmName] Failed to execute build workflow: $e', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
      if (runId != null && runId.isNotEmpty) {
        await _lokiLogger.pushStepEvent(
          runId: runId,
          jobId: job.id,
          stepId: workflowStepId,
          name: 'Run Dart CI Workflow (${job.workflowName})',
          status: BuildJobStatus.FAILURE.name,
          stepOrder: 2,
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }
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

bool _isNoiseLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return true;
  const prefixes = [
    'BASH',
    'DIRSTACK=',
    'EUID=',
    'GROUPS=',
    'HOSTNAME=',
    'HOSTTYPE=',
    'IFS=',
    'MACHTYPE=',
    'OPTERR=',
    'OPTIND=',
    'OSTYPE=',
    'POSIXLY_CORRECT=',
    'PPID=',
    'PS4=',
    'PWD=',
    'SHELL=',
    'SHELLOPTS=',
    'SHLVL=',
    'SSH_CLIENT=',
    'SSH_CONNECTION=',
    'TERM=',
    'TMPDIR=',
    'UID=',
    'USER=',
    '_=',
    'mount_authenticator_shm=',
  ];
  return prefixes.any(trimmed.startsWith);
}
