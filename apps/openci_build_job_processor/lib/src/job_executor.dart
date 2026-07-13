import 'dart:async';
import 'dart:math';

import 'package:lume_dart/lume_dart.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_build_job_processor/src/lume/lume_ssh_service.dart';
import 'package:openci_shared/openci_shared.dart';
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

  Future<void> execute(BuildJob job, String lumeUrl) async {
    final runId = _generateRunId();
    final vmName = 'openci-vm-${job.id}';
    bool isSuccess = false;
    bool vmCreated = false;
    LumeVM? vm;

    try {
      await _createRun(job.id, runId);

      await _prepareVm(
        lumeUrl: lumeUrl,
        baseVmName: _baseVmName,
        vmName: vmName,
        onVmCreated: () => vmCreated = true,
      );

      vm = await _lumeService.waitForVmToBeReady(lumeUrl, vmName);
      await _sshService.setupDirectSsh(vm, runId);

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

  String _generateRunId() {
    final part1 = DateTime.now().millisecondsSinceEpoch;
    final part2 = _random.nextInt(1000000);
    return 'run-$part1-$part2';
  }
}
