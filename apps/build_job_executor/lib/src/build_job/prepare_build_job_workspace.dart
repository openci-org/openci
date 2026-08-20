import 'dart:async';

import 'package:build_job_executor/src/config.dart';
import 'package:build_job_executor/src/loki/loki_logger.dart';
import 'package:build_job_executor/src/orchard/orchard_vm_service.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:retry/retry.dart';
import 'package:sentry/sentry.dart';

class PrepareBuildJobWorkspace {
  PrepareBuildJobWorkspace({
    required OpenCiApiService apiService,
    required OrchardVmService orchardVmService,
    required Config config,
    LokiLogger? lokiLogger,
  }) : _apiService = apiService,
       _orchardVmService = orchardVmService,
       _config = config,
       _lokiLogger = lokiLogger ?? LokiLogger(lokiUrl: config.internalLokiUrl);

  final OpenCiApiService _apiService;
  final OrchardVmService _orchardVmService;
  final Config _config;
  final LokiLogger _lokiLogger;
  final _log = Logger('PrepareBuildJobWorkspace');

  Future<void> call({
    required BuildJob job,
    required String runId,
    required String vmName,
    required void Function() onVmCreated,
  }) async {
    _log.info('[$vmName] Creating run record...');
    await _createRun(job.id, runId);

    _log.info('[$vmName] Resolving GitHub installation token...');
    final token = await _resolveGitHubInstallationToken(job.id);

    const retryOptions = RetryOptions(
      maxAttempts: 60,
      delayFactor: Duration(seconds: 15),
      randomizationFactor: 0.2,
    );

    final prepareStopwatch = Stopwatch()..start();
    _log.info('[$vmName] Preparing VM via Orchard...');
    await _lokiLogger.pushStepEvent(
      runId: runId,
      jobId: job.id,
      stepId: 'prepare_vm',
      name: 'Set up VM',
      status: BuildJobStatus.IN_PROGRESS.name,
      stepOrder: 0,
    );
    await _lokiLogger.pushLog(
      runId: runId,
      jobId: job.id,
      message: 'Preparing macOS VM via Orchard...',
      stepId: 'prepare_vm',
    );
    try {
      await retryOptions.retry(
        () async {
          await _prepareVm(
            baseVmName: _config.baseVmName,
            vmName: vmName,
            onVmCreated: onVmCreated,
          );
        },
        onRetry: (e) async {
          _log.warning(
            '[$vmName] VM preparation failed: $e. Retrying in 15s...',
          );
          await _lokiLogger.pushLog(
            runId: runId,
            jobId: job.id,
            message: 'VM preparation failed: $e. Retrying in 15s...',
            stepId: 'prepare_vm',
            stream: 'stderr',
          );
          try {
            await _orchardVmService.cleanup(vmName);
          } catch (cleanupErr, cleanupStack) {
            _log.warning(
              '[$vmName] Cleanup failed during retry prep: $cleanupErr',
            );
            unawaited(
              Sentry.captureException(cleanupErr, stackTrace: cleanupStack),
            );
          }
        },
      );
      await _lokiLogger.pushStepEvent(
        runId: runId,
        jobId: job.id,
        stepId: 'prepare_vm',
        name: 'Set up VM',
        status: 'SUCCESS',
        stepOrder: 0,
        durationMs: prepareStopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      await _lokiLogger.pushStepEvent(
        runId: runId,
        jobId: job.id,
        stepId: 'prepare_vm',
        name: 'Set up VM',
        status: 'FAILURE',
        stepOrder: 0,
        durationMs: prepareStopwatch.elapsedMilliseconds,
      );
      rethrow;
    }

    final checkoutStopwatch = Stopwatch()..start();
    _log.info('[$vmName] Checking out repository ${job.owner}/${job.repo}...');
    await _lokiLogger.pushStepEvent(
      runId: runId,
      jobId: job.id,
      stepId: 'checkout',
      name: 'Checkout Repository',
      status: BuildJobStatus.IN_PROGRESS.name,
      stepOrder: 1,
    );
    await _lokiLogger.pushLog(
      runId: runId,
      jobId: job.id,
      message: 'Checking out repository ${job.owner}/${job.repo}...',
      stepId: 'checkout',
    );
    try {
      await _checkoutRepository(
        vmName: vmName,
        job: job,
        token: token,
        runId: runId,
      );
      await _lokiLogger.pushStepEvent(
        runId: runId,
        jobId: job.id,
        stepId: 'checkout',
        name: 'Checkout Repository',
        status: 'SUCCESS',
        stepOrder: 1,
        durationMs: checkoutStopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      await _lokiLogger.pushStepEvent(
        runId: runId,
        jobId: job.id,
        stepId: 'checkout',
        name: 'Checkout Repository',
        status: 'FAILURE',
        stepOrder: 1,
        durationMs: checkoutStopwatch.elapsedMilliseconds,
      );
      rethrow;
    }
  }

  Future<void> _prepareVm({
    required String baseVmName,
    required String vmName,
    required void Function() onVmCreated,
  }) async {
    await _orchardVmService.prepare(
      baseInstanceName: baseVmName,
      containerName: vmName,
      onCreated: onVmCreated,
      os: 'darwin',
    );
  }

  Future<void> _checkoutRepository({
    required String vmName,
    required BuildJob job,
    required String token,
    required String runId,
  }) async {
    final baseUrl = job.githubBaseUrl ?? 'https://github.com';
    final repoHost = baseUrl.replaceFirst(RegExp(r'^https?://'), '');
    final repoUrl =
        'https://x-access-token:$token@$repoHost/${job.owner}/${job.repo}.git';

    final String fetchTarget;
    if (job.pullRequestNumber != null) {
      fetchTarget = 'pull/${job.pullRequestNumber}/head';
    } else if (job.commitSha != null && job.commitSha!.isNotEmpty) {
      fetchTarget = job.commitSha!;
    } else {
      fetchTarget = job.branch ?? 'develop';
    }

    final fallbackTarget = job.commitSha ?? job.branch ?? 'develop';

    final checkoutScript =
        '''
set -e
mkdir -p /tmp/workspace
cd /tmp/workspace
if [ ! -d ".git" ]; then
  git init
  git remote add origin "$repoUrl"
fi
if git fetch --depth=1 origin $fetchTarget; then
  git checkout FETCH_HEAD
elif git fetch --depth=1 origin $fallbackTarget; then
  git checkout FETCH_HEAD
else
  git fetch --depth=1 origin HEAD
  git checkout FETCH_HEAD
fi
''';

    await _orchardVmService.writeFile(
      vmName,
      '/tmp/checkout.sh',
      checkoutScript,
      mode: '+x',
    );

    final exitCode = await _orchardVmService.executeCommandStreaming(
      containerName: vmName,
      command: ['/bin/sh', '/tmp/checkout.sh'],
      onLog: (line) {
        _log.fine('[$vmName][checkout] $line');
        if (!_isNoiseLine(line)) {
          _lokiLogger.pushLog(
            runId: runId,
            jobId: job.id,
            message: line,
            stepId: 'checkout',
            command: 'git checkout',
          );
        }
      },
      isCancelled: () async => false,
    );

    if (exitCode != 0) {
      await _lokiLogger.pushLog(
        runId: runId,
        jobId: job.id,
        message: 'Git checkout failed with exit code $exitCode',
        stepId: 'checkout',
        stream: 'stderr',
      );
      throw StateError('Git checkout failed with exit code $exitCode');
    }
  }

  Future<void> _createRun(String jobId, String runId) async {
    final createRunRes = await _apiService
        .createRun(jobId, {'id': runId})
        .timeout(const Duration(seconds: 10));
    if (!createRunRes.isSuccessful) {
      throw Exception(
        'Failed to create run: ${createRunRes.statusCode} - ${createRunRes.error}',
      );
    }
  }

  Future<String> _resolveGitHubInstallationToken(String jobId) async {
    final tokenRes = await _apiService
        .resolveInstallationToken(jobId)
        .timeout(const Duration(seconds: 10));
    if (!tokenRes.isSuccessful) {
      throw Exception(
        'Failed to resolve GitHub App Installation Token: ${tokenRes.statusCode} - ${tokenRes.error}',
      );
    }
    final token = tokenRes.body?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('GitHub Installation Token is null or empty.');
    }
    return token;
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

