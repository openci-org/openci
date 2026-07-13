// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:openci_build_job_processor/openci_build_job_processor.dart';

Future<void> main() async {
  final serverUrl = Platform.environment['OPENCI_SERVER_URL']!;
  final runsOnPattern = Platform.environment['OPENCI_RUNS_ON_PATTERN']!;
  final baseVmName = Platform.environment['LUME_BASE_VM_NAME']!;
  final lumeServerUrls = Platform.environment['LUME_SERVER_URLS']!;
  final tailscaleApiKey = Platform.environment['TAILSCALE_API_KEY']!;
  final tailscaleTailnet = Platform.environment['TAILSCALE_TAILNET']!;

  final lumeServerUrlList = parseLumeServerUrls(lumeServerUrls);

  print('Fetching Lume servers from Tailscale API...');
  try {
    final tailscaleService = TailscaleService(
      apiKey: tailscaleApiKey,
      tailnet: tailscaleTailnet,
    );
    final ips = await tailscaleService.getActiveMacOsIps();
    print('Active macOS Tailscale IPs: $ips');
    for (final ip in ips) {
      final url = 'http://$ip:7777';
      if (!lumeServerUrlList.contains(url)) {
        lumeServerUrlList.add(url);
      }
    }
  } catch (e) {
    stderr.writeln('Failed to fetch Tailscale devices: $e');
  }

  print('Final Lume Server URLs: $lumeServerUrlList');

  if (lumeServerUrlList.isEmpty) {
    throw StateError('No Lume Server URLs available.');
  }
}
