import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:lume_dart/lume_dart.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_build_job_processor/src/logging/build_job_logger.dart';
import 'package:openci_build_job_processor/src/lume/lume_ssh_service.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:retry/retry.dart';
import 'package:sentry/sentry.dart';

class JobExecutor {
  JobExecutor({
    required OpenCiApiService apiService,
    required LumeService lumeService,
    required String baseVmName,
    LumeSshService? sshService,
  }) : _apiService = apiService,
       _lumeService = lumeService,
       _baseVmName = baseVmName,
       _sshService = sshService ?? LumeSshService();

  final OpenCiApiService _apiService;
  final LumeService _lumeService;
  final String _baseVmName;
  final LumeSshService _sshService;
  final _random = Random();
  final _log = Logger('JobExecutor');
  Duration retryDelay = const Duration(seconds: 5);

  Future<void> execute(
    BuildJob job,
    String lumeUrl,
    String runId, {
    required FutureOr<void> Function(LumeVM vm) onVmReady,
  }) async {
    final shortId = job.id.length > 8 ? job.id.substring(0, 8) : job.id;
    final vmName = 'openci-vm-$shortId';
    final jumpHost = Uri.parse(lumeUrl).host;
    bool vmCreated = false;
    LumeVM? vm;

    try {
      _log.info('[$vmName] Starting execute flow. Creating run record...');
      await _createRun(job.id, runId);

      _log.info('[$vmName] Resolving GitHub installation token...');
      final token = await resolveGitHubInstallationToken(job.id);

      const retryOptions = RetryOptions(
        maxAttempts: 2,
        delayFactor: Duration(seconds: 5),
      );
      final prepareVmStart = DateTime.now().toUtc();
      await sendStepStatusUpdate(
        buildJobId: job.id,
        runId: runId,
        stepId: 'prepare_vm',
        name: 'Prepare VM',
        status: BuildJobStatus.IN_PROGRESS.name,
        durationMs: 0,
        stepOrder: 1,
        createdAt: prepareVmStart.toIso8601String(),
        updatedAt: prepareVmStart.toIso8601String(),
      );

      try {
        await retryOptions.retry(
          () async {
            final msg1 = '[$vmName] Preparing VM (cloning & starting)...';
            _log.info(msg1);
            writeBuildStepLog(job.id, runId, 'prepare_vm', msg1);
            await _prepareVm(
              lumeUrl: lumeUrl,
              baseVmName: _baseVmName,
              vmName: vmName,
              onVmCreated: () => vmCreated = true,
            );

            final msg2 =
                '[$vmName] VM clone/run command sent. Waiting for VM to boot and acquire IP...';
            _log.info(msg2);
            writeBuildStepLog(job.id, runId, 'prepare_vm', msg2);
            final currentVm = await _lumeService.waitForVmToBeReady(
              lumeUrl,
              vmName,
            );
            vm = currentVm;

            final msg3 =
                '[$vmName] VM is ready. IP: ${currentVm.ipAddress}. Triggering onVmReady...';
            _log.info(msg3);
            writeBuildStepLog(job.id, runId, 'prepare_vm', msg3);
            await onVmReady(currentVm);

            final msg4 = '[$vmName] Setting up direct SSH keys on VM...';
            _log.info(msg4);
            writeBuildStepLog(job.id, runId, 'prepare_vm', msg4);
            await _sshService.setupDirectSsh(
              currentVm,
              runId,
              jumpHost: jumpHost,
            );
          },
          onRetry: (e) async {
            final warnMsg =
                '[$vmName] VM preparation failed: $e. '
                'Cleaning up failed VM before retry...';
            _log.warning(warnMsg);
            writeBuildStepLog(job.id, runId, 'prepare_vm', warnMsg);
            try {
              await _cleanupVm(lumeUrl, vmName, runId);
              vmCreated = false;
              vm = null;
            } catch (cleanupErr, cleanupStack) {
              final errLog =
                  '[$vmName] Cleanup failed during retry prep: $cleanupErr';
              _log.warning(errLog);
              writeBuildStepLog(job.id, runId, 'prepare_vm', errLog);
              unawaited(
                Sentry.captureException(cleanupErr, stackTrace: cleanupStack),
              );
            }
          },
        );

        final prepareVmEnd = DateTime.now().toUtc();
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'prepare_vm',
          name: 'Prepare VM',
          status: BuildJobStatus.SUCCESS.name,
          durationMs: prepareVmEnd.difference(prepareVmStart).inMilliseconds,
          stepOrder: 1,
          createdAt: prepareVmStart.toIso8601String(),
          updatedAt: prepareVmEnd.toIso8601String(),
        );
        await flushRemainingStepLogs(runId: runId);
      } catch (e) {
        final prepareVmEnd = DateTime.now().toUtc();
        writeBuildStepLog(
          job.id,
          runId,
          'prepare_vm',
          '[$vmName] Prepare VM failed: $e',
        );
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'prepare_vm',
          name: 'Prepare VM',
          status: BuildJobStatus.FAILURE.name,
          durationMs: prepareVmEnd.difference(prepareVmStart).inMilliseconds,
          stepOrder: 1,
          createdAt: prepareVmStart.toIso8601String(),
          updatedAt: prepareVmEnd.toIso8601String(),
        );
        await flushRemainingStepLogs(runId: runId);
        rethrow;
      }

      final finalVm = vm;
      if (finalVm == null) {
        throw StateError('VM was not successfully created or initialized.');
      }
      final ip = finalVm.ipAddress;
      if (ip == null) {
        throw StateError('VM IP is null; cannot checkout repository.');
      }

      final checkoutStart = DateTime.now().toUtc();
      await sendStepStatusUpdate(
        buildJobId: job.id,
        runId: runId,
        stepId: 'checkout',
        name: 'Checkout repository',
        status: BuildJobStatus.IN_PROGRESS.name,
        durationMs: 0,
        stepOrder: 2,
        createdAt: checkoutStart.toIso8601String(),
        updatedAt: checkoutStart.toIso8601String(),
      );

      try {
        final checkoutMsg =
            '[$vmName] Checking out repository ${job.owner}/${job.repo}@${job.commitSha}...';
        _log.info(checkoutMsg);
        writeBuildStepLog(job.id, runId, 'checkout', checkoutMsg);
        await _checkoutRepository(
          ip: ip,
          runId: runId,
          owner: job.owner,
          repo: job.repo,
          commitSha: job.commitSha ?? '',
          token: token,
          githubBaseUrl: job.githubBaseUrl,
          pullRequestNumber: job.pullRequestNumber,
          jumpHost: jumpHost,
        );

        final checkoutEnd = DateTime.now().toUtc();
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'checkout',
          name: 'Checkout repository',
          status: BuildJobStatus.SUCCESS.name,
          durationMs: checkoutEnd.difference(checkoutStart).inMilliseconds,
          stepOrder: 2,
          createdAt: checkoutStart.toIso8601String(),
          updatedAt: checkoutEnd.toIso8601String(),
        );
        await flushRemainingStepLogs(runId: runId);
      } catch (e) {
        final checkoutEnd = DateTime.now().toUtc();
        writeBuildStepLog(
          job.id,
          runId,
          'checkout',
          '[$vmName] Checkout repository failed: $e',
        );
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'checkout',
          name: 'Checkout repository',
          status: BuildJobStatus.FAILURE.name,
          durationMs: checkoutEnd.difference(checkoutStart).inMilliseconds,
          stepOrder: 2,
          createdAt: checkoutStart.toIso8601String(),
          updatedAt: checkoutEnd.toIso8601String(),
        );
        await flushRemainingStepLogs(runId: runId);
        rethrow;
      }

      final secretsStart = DateTime.now().toUtc();
      await sendStepStatusUpdate(
        buildJobId: job.id,
        runId: runId,
        stepId: 'configure_secrets',
        name: 'Configure secrets and script',
        status: BuildJobStatus.IN_PROGRESS.name,
        durationMs: 0,
        stepOrder: 3,
        createdAt: secretsStart.toIso8601String(),
        updatedAt: secretsStart.toIso8601String(),
      );

      try {
        final secMsg1 = '[$vmName] Fetching secrets...';
        _log.info(secMsg1);
        writeBuildStepLog(job.id, runId, 'configure_secrets', secMsg1);
        final secretFileContent = await fetchReferencedSecrets(job.id);

        final secMsg2 = '[$vmName] Writing secrets to VM...';
        _log.info(secMsg2);
        writeBuildStepLog(job.id, runId, 'configure_secrets', secMsg2);
        await _sshService.writeFileToVm(
          ip: ip,
          runId: runId,
          remotePath: '/tmp/openci-secrets',
          content: secretFileContent,
          jumpHost: jumpHost,
        );

        final secMsg3 = '[$vmName] Fetching event payload...';
        _log.info(secMsg3);
        writeBuildStepLog(job.id, runId, 'configure_secrets', secMsg3);
        final eventFileContent = await resolveEventPayload(job.id);

        final secMsg4 = '[$vmName] Writing event payload to VM...';
        _log.info(secMsg4);
        writeBuildStepLog(job.id, runId, 'configure_secrets', secMsg4);
        await _sshService.writeFileToVm(
          ip: ip,
          runId: runId,
          remotePath: '/tmp/openci-event.json',
          content: eventFileContent,
          jumpHost: jumpHost,
        );

        final secMsg5 = '[$vmName] Fetching build script...';
        _log.info(secMsg5);
        writeBuildStepLog(job.id, runId, 'configure_secrets', secMsg5);
        final actScript = await fetchBuildScript(job.id);

        final secMsg6 = '[$vmName] Writing build script to VM...';
        _log.info(secMsg6);
        writeBuildStepLog(job.id, runId, 'configure_secrets', secMsg6);
        await _sshService.writeFileToVm(
          ip: ip,
          runId: runId,
          remotePath: '/tmp/openci-act.sh',
          content: actScript,
          jumpHost: jumpHost,
        );

        final secMsg7 = '[$vmName] Making build script executable...';
        _log.info(secMsg7);
        writeBuildStepLog(job.id, runId, 'configure_secrets', secMsg7);
        final exitCode = await _sshService.executeSshCommand(
          ip: ip,
          runId: runId,
          command: 'chmod +x /tmp/openci-act.sh',
          jumpHost: jumpHost,
        );
        if (exitCode != 0) {
          throw Exception('Failed to chmod act script. Exit code: $exitCode');
        }

        final secretsEnd = DateTime.now().toUtc();
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'configure_secrets',
          name: 'Configure secrets and script',
          status: BuildJobStatus.SUCCESS.name,
          durationMs: secretsEnd.difference(secretsStart).inMilliseconds,
          stepOrder: 3,
          createdAt: secretsStart.toIso8601String(),
          updatedAt: secretsEnd.toIso8601String(),
        );
        await flushRemainingStepLogs(runId: runId);
      } catch (e) {
        final secretsEnd = DateTime.now().toUtc();
        writeBuildStepLog(
          job.id,
          runId,
          'configure_secrets',
          '[$vmName] Configure secrets and script failed: $e',
        );
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'configure_secrets',
          name: 'Configure secrets and script',
          status: BuildJobStatus.FAILURE.name,
          durationMs: secretsEnd.difference(secretsStart).inMilliseconds,
          stepOrder: 3,
          createdAt: secretsStart.toIso8601String(),
          updatedAt: secretsEnd.toIso8601String(),
        );
        await flushRemainingStepLogs(runId: runId);
        rethrow;
      }

      await logInfo(job.id, runId, 'Running workflow with act...');

      BuildJobStatus finalStatus = BuildJobStatus.SUCCESS;

      try {
        await _sshService.execCommandStreaming(
          command: ['/bin/zsh', '-l', '/tmp/openci-act.sh'],
          ip: ip,
          buildJobId: job.id,
          runId: runId,
          token: token,
          isCancelled: () => _isCancelled(job.id),
          jumpHost: jumpHost,
        );
        await logInfo(job.id, runId, 'Build completed successfully');
      } on TimeoutException catch (timeoutError) {
        await logError(job.id, runId, 'Job execution timed out: $timeoutError');
        finalStatus = BuildJobStatus.TIMED_OUT;
      } catch (actError) {
        if (await _isCancelled(job.id)) {
          await logInfo(job.id, runId, 'Build was cancelled by user');
          finalStatus = BuildJobStatus.CANCELLED;
        } else {
          await logWarning(job.id, runId, 'Act build failed: $actError');
          finalStatus = BuildJobStatus.FAILURE;
        }
      }

      await _updateJobFinalStatus(
        jobId: job.id,
        runId: runId,
        status: finalStatus,
        conclusion: finalStatus.name.toLowerCase(),
        buildJob: job,
      );
    } catch (e, s) {
      _log.severe('CRITICAL EXCEPTION IN JOB EXECUTOR', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
      await _updateJobFinalStatus(
        jobId: job.id,
        runId: runId,
        status: BuildJobStatus.FAILURE,
        conclusion: BuildJobStatus.FAILURE.name.toLowerCase(),
        buildJob: job,
      );
    } finally {
      if (vmCreated) {
        _log.info('[$vmName] Triggering VM cleanup...');
        try {
          await _cleanupVm(lumeUrl, vmName, runId);
          _log.info('[$vmName] VM cleanup completed.');
        } catch (e) {
          _log.warning('[$vmName] Failed to cleanup VM: $e');
        }
      }
      _log.info('[$vmName] Cleaning up temporary SSH keys...');
      _sshService.cleanupTempSshKeys(runId);
      _log.info('[$vmName] Flushing remaining logs...');
      await flushRemainingLogs(runId: runId);
      _log.info('[$vmName] Execute flow fully completed.');
    }
  }

  Future<void> _cleanupVm(String lumeUrl, String vmName, String runId) async {
    try {
      await _lumeService.stopVm(lumeUrl, vmName);
      await _lumeService.waitForVmToBeStopped(lumeUrl, vmName);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    try {
      await _lumeService.deleteVm(lumeUrl, vmName);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    try {
      final jumpHost = Uri.parse(lumeUrl).host;
      await _sshService.clearArpCache(jumpHost: jumpHost, runId: runId);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
  }

  Future<void> _updateJobFinalStatus({
    required String jobId,
    required String runId,
    required BuildJobStatus status,
    required String conclusion,
    required BuildJob buildJob,
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

  Future<void> _prepareVm({
    required String lumeUrl,
    required String baseVmName,
    required String vmName,
    required void Function() onVmCreated,
  }) async {
    try {
      await _lumeService.stopVm(lumeUrl, vmName);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
    try {
      await _lumeService.deleteVm(lumeUrl, vmName);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    await _lumeService.cloneVm(lumeUrl, baseVmName, vmName);
    onVmCreated();

    await _lumeService.runVm(lumeUrl, vmName);
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

  Future<String> resolveGitHubInstallationToken(String jobId) async {
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

  String generateRunId() {
    final part1 = DateTime.now().millisecondsSinceEpoch;
    final part2 = _random.nextInt(1000000);
    return 'run-$part1-$part2';
  }

  Future<void> _checkoutRepository({
    required String ip,
    required String runId,
    required String owner,
    required String repo,
    required String commitSha,
    required String token,
    required String? githubBaseUrl,
    required int? pullRequestNumber,
    required String jumpHost,
  }) async {
    final githubHost = githubBaseUrl != null
        ? Uri.parse(githubBaseUrl).host
        : 'github.com';
    final cloneUrl =
        'https://x-access-token:$token@$githubHost/$owner/$repo.git';

    await retry(
      () async {
        final exitCode = await _sshService.executeSshCommand(
          ip: ip,
          runId: runId,
          command: 'git clone --depth 1 --no-checkout $cloneUrl',
          jumpHost: jumpHost,
        );
        if (exitCode != 0) {
          throw Exception('Failed to clone repository. Exit code: $exitCode');
        }
      },
      delayFactor: retryDelay,
      randomizationFactor: 0,
      maxAttempts: 3,
    );

    var exitCode = -1;
    var fetchCommand = 'git -C $repo fetch --depth 1 origin $commitSha';
    exitCode = await _sshService.executeSshCommand(
      ip: ip,
      runId: runId,
      command: fetchCommand,
      jumpHost: jumpHost,
    );

    if (exitCode != 0 && pullRequestNumber != null) {
      fetchCommand =
          'git -C $repo fetch --depth 1 origin pull/$pullRequestNumber/head';
      exitCode = await _sshService.executeSshCommand(
        ip: ip,
        runId: runId,
        command: fetchCommand,
        jumpHost: jumpHost,
      );
    }
    if (exitCode != 0) {
      throw Exception('Failed to fetch commit. Exit code: $exitCode');
    }

    exitCode = await _sshService.executeSshCommand(
      ip: ip,
      runId: runId,
      command: 'git -C $repo checkout $commitSha',
      jumpHost: jumpHost,
    );
    if (exitCode != 0) {
      throw Exception('Failed to checkout commit. Exit code: $exitCode');
    }
  }

  Future<String> fetchReferencedSecrets(String buildJobId) async {
    final response = await _apiService.getJobSecrets(buildJobId);
    if (!response.isSuccessful) {
      throw Exception(
        'Failed to get job secrets: ${response.statusCode} - ${response.error}',
      );
    }

    final body = response.body;
    if (body == null) return '';

    return body['secretsContent'] as String? ?? '';
  }

  Future<String> resolveEventPayload(String buildJobId) async {
    final response = await _apiService.getJobEventPayload(buildJobId);
    if (!response.isSuccessful) {
      throw Exception(
        'Failed to get job event payload: ${response.statusCode} - ${response.error}',
      );
    }

    final body = response.body;
    if (body == null) return '';

    return body['eventPayload'] as String? ?? '';
  }

  Future<String> fetchBuildScript(String buildJobId) async {
    final response = await _apiService.getJobBuildScript(buildJobId);
    if (!response.isSuccessful) {
      throw Exception(
        'Failed to get job build script: ${response.statusCode} - ${response.error}',
      );
    }

    final body = response.body;
    if (body == null) return '';

    return body['script'] as String? ?? '';
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
