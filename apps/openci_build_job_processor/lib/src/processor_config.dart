import 'dart:io';

class ProcessorConfig {
  ProcessorConfig({
    required this.serverUrl,
    required this.runsOnPattern,
    required this.baseVmName,
    required this.tailscaleApiKey,
    required this.tailscaleTailnet,
    required this.internalApiKey,
    this.sentryDsn,
  });

  final String serverUrl;
  final String runsOnPattern;
  final String baseVmName;
  final String tailscaleApiKey;
  final String tailscaleTailnet;
  final String internalApiKey;
  final String? sentryDsn;

  factory ProcessorConfig.fromEnvironment() {
    String getRequired(String key) {
      final value = Platform.environment[key];
      if (value == null || value.isEmpty) {
        throw StateError('必要な環境変数 $key が設定されていません。');
      }
      return value;
    }

    return ProcessorConfig(
      serverUrl: getRequired('OPENCI_SERVER_URL'),
      runsOnPattern: getRequired('OPENCI_RUNS_ON_PATTERN'),
      baseVmName: getRequired('LUME_BASE_VM_NAME'),
      tailscaleApiKey: getRequired('TAILSCALE_API_KEY'),
      tailscaleTailnet: getRequired('TAILSCALE_TAILNET'),
      internalApiKey: getRequired('INTERNAL_API_KEY'),
      sentryDsn: Platform.environment['SENTRY_DSN'],
    );
  }
}
