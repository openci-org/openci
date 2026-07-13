// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:openci_build_job_processor/openci_build_job_processor.dart';

Future<void> main() async {
  final serverUrl = Platform.environment['OPENCI_SERVER_URL']!;
  final runsOnPattern = Platform.environment['OPENCI_RUNS_ON_PATTERN']!;
  final baseVmName = Platform.environment['LUME_BASE_VM_NAME']!;
  final tailscaleApiKey = Platform.environment['TAILSCALE_API_KEY']!;
  final tailscaleTailnet = Platform.environment['TAILSCALE_TAILNET']!;

  final tailscaleService = TailscaleService(
    apiKey: tailscaleApiKey,
    tailnet: tailscaleTailnet,
  );
  final ips = await tailscaleService.getActiveMacOsIps();

  final lumeServerUrlList = ips.map((ip) => 'http://$ip:7777').toList();

  if (lumeServerUrlList.isEmpty) {
    throw StateError('No Lume Server URLs available.');
  }
}
