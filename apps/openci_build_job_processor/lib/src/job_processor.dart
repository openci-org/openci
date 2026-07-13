// ignore_for_file: avoid_print

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
    print('Starting job polling for pattern: $runsOnPattern');

    while (true) {
      try {
        final ips = await _tailscaleService.getActiveMacOsIps();
        final lumeServerUrls = ips.map((ip) => 'http://$ip:7777').toList();

        if (lumeServerUrls.isEmpty) {
          print('No active macOS hosts found via Tailscale.');
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        final availableLumeUrl = await _lumeService.findAvailableLumeUrl(
          lumeServerUrls,
        );

        if (availableLumeUrl == null) {
          print('All macOS hosts are busy (running >= 2 VMs).');
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        final response = await _apiService.claimNextJob({
          'runsOnPattern': runsOnPattern,
        });

        if (!response.isSuccessful) {
          print('Failed to claim job: ${response.error}');
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        final body = response.body;
        if (body == null || body['job'] == null) {
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        final jobMap = body['job'] as Map<String, dynamic>;
        final job = BuildJob.fromJson(jobMap);

        print(
          'Claimed job: ${job.id} for ${job.owner}/${job.repo} on Lume host: $availableLumeUrl',
        );

        unawaited(_processJob(job, availableLumeUrl));
      } catch (e, s) {
        print('Error in polling loop: $e\n$s');
        await Future<void>.delayed(const Duration(seconds: 10));
      }
    }
  }

  Future<void> _processJob(BuildJob job, String lumeUrl) async {
    final runId = _generateRunId();
    print(
      'Starting build run: $runId for job: ${job.id} on Lume host: $lumeUrl',
    );

    try {
      final createRunRes = await _apiService.createRun(job.id, {'id': runId});
      if (!createRunRes.isSuccessful) {
        print('Failed to create run: ${createRunRes.error}');
        return;
      }
    } catch (e) {
      print('Exception while creating run: $e');
      return;
    }

    bool isSuccess = false;
    final vmName = 'openci-vm-${job.id}';
    final baseVmName =
        Platform.environment['LUME_BASE_VM_NAME'] ?? 'tahoe-base_v1.2.3';

    try {
      print('Cloning VM from $baseVmName to $vmName on Lume host $lumeUrl...');
      await _lumeService.cloneVm(lumeUrl, baseVmName, vmName);

      print('Starting VM $vmName on Lume host $lumeUrl...');
      await _lumeService.runVm(lumeUrl, vmName);

      print('Waiting for VM $vmName to be ready...');
      final vm = await _lumeService.waitForVmToBeReady(lumeUrl, vmName);
      print(
        'VM $vmName is ready on IP ${vm.ipAddress}. Executing job steps...',
      );

      await Future<void>.delayed(const Duration(seconds: 5));
      isSuccess = true;
    } catch (e) {
      print('Exception during VM operation or job execution: $e');
    } finally {
      try {
        print('Stopping VM $vmName on Lume host $lumeUrl...');
        await _lumeService.stopVm(lumeUrl, vmName);
      } catch (e) {
        print('Failed to stop VM $vmName: $e');
      }

      try {
        print('Deleting VM $vmName on Lume host $lumeUrl...');
        await _lumeService.deleteVm(lumeUrl, vmName);
      } catch (e) {
        print('Failed to delete VM $vmName: $e');
      }
    }

    try {
      final updateRunRes = await _apiService.updateRunStatus(job.id, runId, {
        'status': 'completed',
        'conclusion': isSuccess ? 'success' : 'failure',
      });
      if (!updateRunRes.isSuccessful) {
        print('Failed to update run status: ${updateRunRes.error}');
      }
    } catch (e) {
      print('Exception while updating run status: $e');
    }

    try {
      final completeJobRes = await _apiService.completeJob(job.id, {
        'status': isSuccess
            ? BuildJobStatus.SUCCESS.name
            : BuildJobStatus.FAILURE.name,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
      });
      if (!completeJobRes.isSuccessful) {
        print('Failed to complete job: ${completeJobRes.error}');
      } else {
        print(
          'Completed job: ${job.id} with status: ${isSuccess ? "SUCCESS" : "FAILURE"}',
        );
      }
    } catch (e) {
      print('Exception while completing job: $e');
    }
  }

  String _generateRunId() {
    final part1 = DateTime.now().millisecondsSinceEpoch;
    final part2 = _random.nextInt(1000000);
    return 'run-$part1-$part2';
  }
}
