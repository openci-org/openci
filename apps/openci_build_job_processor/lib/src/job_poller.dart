import 'dart:async';

import 'package:logging/logging.dart';
import 'package:lume_dart/lume_dart.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_build_job_processor/src/logging/build_job_logger.dart';
import 'package:openci_build_job_processor/src/lume/lume_ssh_service.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('JobPoller');

class JobPoller {
  JobPoller({
    required ProcessorConfig config,
    OpenCiApiService? apiService,
    TailscaleService? tailscaleService,
    LumeService? lumeService,
    LumeSshService? sshService,
  }) : _apiService =
           apiService ??
           createOpenCiChopperClient(
             baseUrl: config.serverUrl,
             tokenProvider: () => config.internalApiKey,
             services: [OpenCiApiService.create()],
           ).getService<OpenCiApiService>(),
       _tailscaleService =
           tailscaleService ??
           TailscaleService(
             apiKey: config.tailscaleApiKey,
             tailnet: config.tailscaleTailnet,
             excludeIps: config.excludeIps,
           ),
       _lumeService = lumeService ?? LumeService(),
       _sshService = sshService ?? LumeSshService(),
       _baseVmName = config.baseVmName,
       _maxConcurrentJobs = config.maxConcurrentJobs {
    setupBuildJobLogger(
      serverUrl: config.serverUrl,
      internalApiKey: config.internalApiKey,
    );
    setupBuildStepLogger(
      serverUrl: config.serverUrl,
      internalApiKey: config.internalApiKey,
    );
  }

  final OpenCiApiService _apiService;
  final TailscaleService _tailscaleService;
  final LumeService _lumeService;
  final LumeSshService _sshService;
  final String _baseVmName;
  int _activeJobsCount = 0;
  final int _maxConcurrentJobs;
  final _activeJobs = <String, ({DateTime startTime, String host})>{};

  Future<void> startPolling(String runsOnPattern) async {
    _log.info('JobPoller started polling for pattern: $runsOnPattern');

    try {
      await pruneZombieVms();
    } catch (e) {
      _log.warning('Failed to complete VM pruning initialization: $e');
    }

    Timer.periodic(const Duration(seconds: 30), (_) => _logActiveJobs());

    while (true) {
      try {
        if (_activeJobsCount >= _maxConcurrentJobs) {
          _log.info(
            'Active jobs $_activeJobsCount >= max $_maxConcurrentJobs. Waiting...',
          );
          await Future<void>.delayed(const Duration(seconds: 5));
          continue;
        }

        _log.info('Checking for available Lume hosts...');
        final availableLumeUrl = await _findAvailableLumeUrl();
        if (availableLumeUrl == null) {
          _log.info('No available Lume hosts found. Retrying in 10 seconds...');
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        _log.info(
          'Available Lume host found: $availableLumeUrl. Claiming next job for pattern: $runsOnPattern...',
        );
        final job = await _claimNextJob(runsOnPattern);
        if (job == null) {
          _log.info(
            'No queued jobs found for pattern: $runsOnPattern. Retrying in 10 seconds...',
          );
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        _log.info('Job claimed: ${job.id}. Starting build execution...');

        final executor = JobExecutor(
          apiService: _apiService,
          lumeService: _lumeService,
          baseVmName: _baseVmName,
        );

        final runId = executor.generateRunId();
        final vmReadyCompleter = Completer<LumeVM>();
        final shortId = job.id.length > 8 ? job.id.substring(0, 8) : job.id;
        final vmName = 'openci-vm-$shortId';

        final hostIp = Uri.parse(availableLumeUrl).host;
        _activeJobs[vmName] = (startTime: DateTime.now(), host: hostIp);
        _activeJobsCount++;

        unawaited(() async {
          try {
            await executor.execute(
              job,
              availableLumeUrl,
              runId,
              onVmReady: (vm) {
                vmReadyCompleter.complete(vm);
              },
            );
          } catch (e) {
            if (!vmReadyCompleter.isCompleted) {
              vmReadyCompleter.completeError(e);
            }
          } finally {
            _activeJobs.remove(vmName);
            _activeJobsCount--;
          }
        }());

        // VMが起動完了するまで同期的に待つ（同じホストへの同時アサイン競合を防ぐ）
        try {
          await vmReadyCompleter.future;
        } catch (e, s) {
          unawaited(Sentry.captureException(e, stackTrace: s));
          // VM起動エラーの場合は、そのジョブの終了を待ちつつ次のループへ進む
          continue;
        }
      } catch (e, s) {
        _log.severe('Error in polling loop: $e', e, s);
        unawaited(Sentry.captureException(e, stackTrace: s));
        await Future<void>.delayed(const Duration(seconds: 10));
      }
    }
  }

  Future<String?> _findAvailableLumeUrl() async {
    final ips = await _tailscaleService.getActiveMacOsIps();
    _log.info('Detected Tailscale macOS IPs: $ips');
    final lumeServerUrls = ips.map((ip) => 'http://$ip:7777').toList();

    if (lumeServerUrls.isEmpty) {
      return null;
    }

    final selectedUrl = await _lumeService.findAvailableLumeUrl(lumeServerUrls);
    _log.info('Selected Lume host: $selectedUrl');
    return selectedUrl;
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

  void _logActiveJobs() {
    if (_activeJobs.isEmpty) {
      _log.info('Active jobs: 0 / $_maxConcurrentJobs');
      return;
    }
    final buffer = StringBuffer(
      '\n=== Active Jobs Running: ${_activeJobs.length} / $_maxConcurrentJobs ===',
    );
    final now = DateTime.now();
    _activeJobs.forEach((vmName, info) {
      final diff = now.difference(info.startTime);
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      final timeStr = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
      buffer.write('\n  - $vmName (on ${info.host}): Running for $timeStr');
    });
    buffer.write('\n===========================');
    _log.info(buffer.toString());
  }

  Future<void> pruneZombieVms() async {
    _log.info('Initializing: Pruning any zombie build VMs on macOS hosts...');
    final ips = await _tailscaleService.getActiveMacOsIps();
    for (final ip in ips) {
      final lumeUrl = 'http://$ip:7777';
      try {
        final vms = await _lumeService.getVms(lumeUrl);
        bool didPrune = false;
        for (final vm in vms) {
          if (vm.name.startsWith('openci-vm-') && vm.name != _baseVmName) {
            _log.info(
              'Pruning zombie VM: ${vm.name} (status: ${vm.status}) on $lumeUrl',
            );
            try {
              if (vm.status.toLowerCase() == 'running') {
                await _lumeService.stopVm(lumeUrl, vm.name);
                await _lumeService.waitForVmToBeStopped(lumeUrl, vm.name);
              }
              await _lumeService.deleteVm(lumeUrl, vm.name);
              _log.info('Successfully pruned zombie VM: ${vm.name}');
              didPrune = true;
            } catch (e, s) {
              _log.warning('Failed to prune zombie VM ${vm.name}', e, s);
              unawaited(Sentry.captureException(e, stackTrace: s));
            }
          }
        }
        if (didPrune) {
          final runId = 'prune-${DateTime.now().millisecondsSinceEpoch}';
          await _sshService.clearArpCache(jumpHost: ip, runId: runId);
        }
      } catch (e, s) {
        _log.warning('Failed to prune VMs on $lumeUrl', e, s);
        unawaited(Sentry.captureException(e, stackTrace: s));
      }
    }
    _log.info('Initialization complete: Zombie VMs pruned.');
  }
}
