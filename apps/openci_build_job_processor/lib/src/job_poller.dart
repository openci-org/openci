import 'dart:async';

import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

class JobPoller {
  JobPoller({
    required OpenCiApiService apiService,
    required TailscaleService tailscaleService,
    required LumeService lumeService,
  }) : _apiService = apiService,
       _tailscaleService = tailscaleService,
       _lumeService = lumeService;

  final OpenCiApiService _apiService;
  final TailscaleService _tailscaleService;
  final LumeService _lumeService;

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

        final executor = JobExecutor(
          apiService: _apiService,
          lumeService: _lumeService,
        );
        unawaited(executor.execute(job, availableLumeUrl));
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
