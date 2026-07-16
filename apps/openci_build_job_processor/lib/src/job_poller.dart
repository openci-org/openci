import 'dart:async';

import 'package:lume_dart/lume_dart.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_build_job_processor/src/logging/build_job_logger.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

class JobPoller {
  JobPoller({
    required ProcessorConfig config,
    OpenCiApiService? apiService,
    TailscaleService? tailscaleService,
    LumeService? lumeService,
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
       _baseVmName = config.baseVmName {
    setupBuildJobLogger(
      serverUrl: config.serverUrl,
      internalApiKey: config.internalApiKey,
    );
  }

  final OpenCiApiService _apiService;
  final TailscaleService _tailscaleService;
  final LumeService _lumeService;
  final String _baseVmName;
  int _activeJobsCount = 0;
  static const _maxConcurrentJobs = 3;

  Future<void> startPolling(String runsOnPattern) async {
    while (true) {
      try {
        if (_activeJobsCount >= _maxConcurrentJobs) {
          await Future<void>.delayed(const Duration(seconds: 5));
          continue;
        }

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

        final executor = JobExecutor(
          apiService: _apiService,
          lumeService: _lumeService,
          baseVmName: _baseVmName,
        );

        final runId = executor.generateRunId();
        final vmReadyCompleter = Completer<LumeVM>();

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
            _activeJobsCount--;
          }
        }());

        // VMが起動完了するまで同期的に待つ（同じホストへの同時アサイン競合を防ぐ）
        try {
          await vmReadyCompleter.future;
        } catch (_) {
          // VM起動エラーの場合は、そのジョブの終了を待ちつつ次のループへ進む
          continue;
        }
      } catch (e, s) {
        await Sentry.captureException(e, stackTrace: s);
        await Future<void>.delayed(const Duration(seconds: 10));
      }
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
}
