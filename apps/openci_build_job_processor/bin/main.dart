// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_shared/openci_shared.dart';

Future<void> main() async {
  final serverUrl = Platform.environment['OPENCI_SERVER_URL']!;
  final runsOnPattern = Platform.environment['OPENCI_RUNS_ON_PATTERN']!;
  final baseVmName = Platform.environment['LUME_BASE_VM_NAME']!;
  final tailscaleApiKey = Platform.environment['TAILSCALE_API_KEY']!;
  final tailscaleTailnet = Platform.environment['TAILSCALE_TAILNET']!;
  final internalApiKey = Platform.environment['INTERNAL_API_KEY']!;

  final chopperClient = createOpenCiChopperClient(
    baseUrl: serverUrl,
    tokenProvider: () => internalApiKey,
    services: [OpenCiApiService.create()],
  );
  final apiService = chopperClient.getService<OpenCiApiService>();

  final tailscaleService = TailscaleService(
    apiKey: tailscaleApiKey,
    tailnet: tailscaleTailnet,
  );
  final lumeService = LumeService();

  final jobProcessor = JobProcessor(
    apiService: apiService,
    tailscaleService: tailscaleService,
    lumeService: lumeService,
  );
  await jobProcessor.startPolling(runsOnPattern);
}
