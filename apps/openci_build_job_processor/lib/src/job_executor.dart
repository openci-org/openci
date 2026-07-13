import 'dart:async';
import 'dart:math';

import 'package:lume_dart/lume_dart.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_build_job_processor/src/lume/lume_ssh_service.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:retry/retry.dart';
import 'package:sentry/sentry.dart';

class JobExecutor {
  JobExecutor({
    required OpenCiApiService apiService,
    required LumeService lumeService,
    required String baseVmName,
    required String serverUrl,
    required String internalApiKey,
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
    bool isSuccess = false;
    bool vmCreated = false;
    LumeVM? vm;

    try {
      await _createRun(job.id, runId);

      final token = await resolveGitHubInstallationToken(job.id);

      await _prepareVm(
        lumeUrl: lumeUrl,
        baseVmName: _baseVmName,
        vmName: vmName,
        onVmCreated: () => vmCreated = true,
      );

      vm = await _lumeService.waitForVmToBeReady(lumeUrl, vmName);
      await _sshService.setupDirectSsh(vm, runId);

      final ip = vm.ipAddress;
      if (ip == null) {
        throw StateError('VM IP is null; cannot checkout repository.');
      }

      await _checkoutRepository(
        ip: ip,
        runId: runId,
        owner: job.owner,
        repo: job.repo,
        commitSha: job.commitSha ?? '',
        token: token,
        githubBaseUrl: job.githubBaseUrl,
        pullRequestNumber: job.pullRequestNumber,
      );

      isSuccess = true;
      // start processing build job
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
    } finally {
      if (vmCreated) {
        await _cleanupVm(lumeUrl, vmName);
      }
      _sshService.cleanupTempSshKeys(runId);
    }

    await _completeJob(job.id, runId, isSuccess);
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

  Future<void> _completeJob(String jobId, String runId, bool isSuccess) async {
    try {
      await _apiService.updateRunStatus(jobId, runId, {
        'status': 'completed',
        'conclusion': isSuccess ? 'success' : 'failure',
      });
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
    }

    try {
      await _apiService.completeJob(jobId, {
        'status': isSuccess
            ? BuildJobStatus.SUCCESS.name
            : BuildJobStatus.FAILURE.name,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
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
    );

    if (exitCode != 0 && pullRequestNumber != null) {
      fetchCommand =
          'git -C $repo fetch --depth 1 origin pull/$pullRequestNumber/head';
      exitCode = await _sshService.executeSshCommand(
        ip: ip,
        runId: runId,
        command: fetchCommand,
      );
    }
    if (exitCode != 0) {
      throw Exception('Failed to fetch commit. Exit code: $exitCode');
    }

    exitCode = await _sshService.executeSshCommand(
      ip: ip,
      runId: runId,
      command: 'git -C $repo checkout $commitSha',
    );
    if (exitCode != 0) {
      throw Exception('Failed to checkout commit. Exit code: $exitCode');
    }
  }
}
