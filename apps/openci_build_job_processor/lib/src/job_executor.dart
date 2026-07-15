import 'dart:async';
import 'dart:math';

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
  Duration retryDelay = const Duration(seconds: 5);

  Future<void> execute(BuildJob job, String lumeUrl) async {
    final runId = _generateRunId();
    final vmName = 'openci-vm-${job.id}';
    bool vmCreated = false;
    LumeVM? vm;

    final jumpHost = Uri.parse(lumeUrl).host;

    try {
      await _createRun(job.id, runId);
      await logInfo(job.id, runId, 'Job execution started on platform: ${job.runsOn}');

      final token = await resolveGitHubInstallationToken(job.id);

      await logInfo(job.id, runId, 'Preparing Lume VM "$vmName" on host...');
      await _prepareVm(
        lumeUrl: lumeUrl,
        baseVmName: _baseVmName,
        vmName: vmName,
        onVmCreated: () => vmCreated = true,
      );

      await logInfo(job.id, runId, 'Waiting for VM to boot and obtain IP...');
      vm = await _lumeService.waitForVmToBeReady(lumeUrl, vmName);

      await logInfo(job.id, runId, 'Setting up SSH access key on VM...');
      await _sshService.setupDirectSsh(vm, runId, jumpHost);

      final ip = vm.ipAddress;
      if (ip == null) {
        throw StateError('VM IP is null; cannot checkout repository.');
      }

      await logInfo(job.id, runId, 'Cloning repository ${job.owner}/${job.repo}...');
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

      await logInfo(job.id, runId, 'Injecting build secrets and environment config...');
      final secretFileContent = await fetchReferencedSecrets(job.id);

      await _sshService.writeFileToVm(
        ip: ip,
        runId: runId,
        remotePath: '/tmp/openci-secrets',
        content: secretFileContent,
        jumpHost: jumpHost,
      );

      final eventFileContent = await resolveEventPayload(job.id);
      await _sshService.writeFileToVm(
        ip: ip,
        runId: runId,
        remotePath: '/tmp/openci-event.json',
        content: eventFileContent,
        jumpHost: jumpHost,
      );

      final actScript = await fetchBuildScript(job.id);

      await _sshService.writeFileToVm(
        ip: ip,
        runId: runId,
        remotePath: '/tmp/openci-act.sh',
        content: actScript,
        jumpHost: jumpHost,
      );

      final exitCode = await _sshService.executeSshCommand(
        ip: ip,
        runId: runId,
        command: 'chmod +x /tmp/openci-act.sh',
        jumpHost: jumpHost,
      );
      if (exitCode != 0) {
        throw Exception('Failed to chmod act script. Exit code: $exitCode');
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
      await logError(job.id, runId, 'Job executor failed: $e', stackTrace: s.toString());
      await Sentry.captureException(e, stackTrace: s);
      await _updateJobFinalStatus(
        jobId: job.id,
        runId: runId,
        status: BuildJobStatus.FAILURE,
        conclusion: BuildJobStatus.FAILURE.name.toLowerCase(),
        buildJob: job,
      );
    } finally {
      if (vmCreated) {
        await _cleanupVm(lumeUrl, vmName);
      }
      _sshService.cleanupTempSshKeys(runId);
      await flushRemainingLogs(runId: runId);
    }
  }

  Future<void> _cleanupVm(String lumeUrl, String vmName) async {
    try {
      await _lumeService.stopVm(lumeUrl, vmName);
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
    }

    try {
      await _lumeService.deleteVm(lumeUrl, vmName);
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
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
      await _apiService.updateRunStatus(jobId, runId, {
        'status': 'completed',
        'conclusion': conclusion,
      });
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
    }

    try {
      await _apiService.completeJob(jobId, {
        'status': status.name,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
    }

    try {
      await _apiService.updateCheckRun(jobId, {
        'status': 'completed',
        'conclusion': conclusion,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await _apiService.handleBuildJobStatusChange(jobId, {
        'status': status.name,
      });
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
    }
  }

  Future<void> _prepareVm({
    required String lumeUrl,
    required String baseVmName,
    required String vmName,
    required void Function() onVmCreated,
  }) async {
    await _lumeService.cloneVm(lumeUrl, baseVmName, vmName);
    onVmCreated();

    await _lumeService.runVm(lumeUrl, vmName);
  }

  Future<void> _createRun(String jobId, String runId) async {
    final createRunRes = await _apiService.createRun(jobId, {'id': runId});
    if (!createRunRes.isSuccessful) {
      throw Exception(
        'Failed to create run: ${createRunRes.statusCode} - ${createRunRes.error}',
      );
    }
  }

  Future<String> resolveGitHubInstallationToken(String jobId) async {
    final tokenRes = await _apiService.resolveInstallationToken(jobId);
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

  String _generateRunId() {
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
    String? jumpHost,
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
      final res = await _apiService.getBuildJob(jobId);
      if (res.isSuccessful) {
        final updatedJob = res.body;
        return updatedJob?['status'] == BuildJobStatus.CANCELLED.name ||
            updatedJob?['status'] == 'CANCELLING';
      }
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
    }
    return false;
  }
}
