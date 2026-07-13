import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_shared/openci_shared.dart';

class JobProcessor {
  JobProcessor({
    required OpenCiApiService apiService,
    required TailscaleService tailscaleService,
    required LumeService lumeService,
  }) : _apiService = apiService,
       _tailscaleService = tailscaleService,
       _lumeService = lumeService;

  final OpenCiApiService _apiService;
  final TailscaleService _tailscaleService;
  final LumeService _lumeService;
  final _random = Random();

  Future<void> startPolling(String runsOnPattern) async {
    while (true) {
      try {
        final availableLumeUrl = await _findAvailableLumeUrl();
        if (availableLumeUrl == null) {
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        final job = await _claimNextJob(runsOnPattern);
        if (job == null) {
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        unawaited(_processJob(job, availableLumeUrl));
      } catch (e) {
        await Future<void>.delayed(const Duration(seconds: 10));
      }
    }
  }

  Future<void> _processJob(BuildJob job, String lumeUrl) async {
    final runId = _generateRunId();

    try {
      final createRunRes = await _apiService.createRun(job.id, {'id': runId});
      if (!createRunRes.isSuccessful) {
        return;
      }
    } catch (e) {
      return;
    }

    bool isSuccess = false;
    final vmName = 'openci-vm-${job.id}';
    final baseVmName =
        Platform.environment['LUME_BASE_VM_NAME'] ?? 'tahoe-base_v1.2.3';

    try {
      await _lumeService.cloneVm(lumeUrl, baseVmName, vmName);
      await _lumeService.runVm(lumeUrl, vmName);
      await _lumeService.waitForVmToBeReady(lumeUrl, vmName);

      await Future<void>.delayed(const Duration(seconds: 5));
      isSuccess = true;
    } catch (e) {
      // Error ignored or handled silently
    } finally {
      try {
        await _lumeService.stopVm(lumeUrl, vmName);
      } catch (e) {
        // Error ignored
      }

      try {
        await _lumeService.deleteVm(lumeUrl, vmName);
      } catch (e) {
        // Error ignored
      }
    }

    try {
      await _apiService.updateRunStatus(job.id, runId, {
        'status': 'completed',
        'conclusion': isSuccess ? 'success' : 'failure',
      });
    } catch (e) {
      // Error ignored
    }

    try {
      await _apiService.completeJob(job.id, {
        'status': isSuccess
            ? BuildJobStatus.SUCCESS.name
            : BuildJobStatus.FAILURE.name,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Error ignored
    }
  }

  Future<String?> _findAvailableLumeUrl() async {
    final ips = await _tailscaleService.getActiveMacOsIps();
    final lumeServerUrls = ips.map((ip) => 'http://$ip:7777').toList();

    if (lumeServerUrls.isEmpty) {
      return null;
    }

    return _lumeService.findAvailableLumeUrl(lumeServerUrls);
  }

  Future<BuildJob?> _claimNextJob(String runsOnPattern) async {
    final response = await _apiService.claimNextJob({
      'runsOnPattern': runsOnPattern,
    });

    if (!response.isSuccessful) {
      throw Exception(
        'Failed to claim next job: ${response.statusCode} - ${response.error}',
      );
    }

    final body = response.body;
    if (body == null) {
      throw Exception('Failed to claim next job: Response body is null');
    }

    final jobMap = body['job'] as Map<String, dynamic>?;
    if (jobMap == null) {
      return null;
    }

    return BuildJob.fromJson(jobMap);
  }

  String _generateRunId() {
    final part1 = DateTime.now().millisecondsSinceEpoch;
    final part2 = _random.nextInt(1000000);
    return 'run-$part1-$part2';
  }
}
