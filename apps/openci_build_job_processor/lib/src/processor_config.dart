import 'dart:io';

class ProcessorConfig {
  ProcessorConfig({
    required this.serverUrl,
    required this.runsOnPattern,
    required this.baseVmName,
    required this.tailscaleApiKey,
    required this.tailscaleTailnet,
    required this.internalApiKey,
    this.excludeIps = const [],
    this.sentryDsn,
    this.maxConcurrentJobs = 3,
    this.useOrchard = false,
    this.orchardApiUrl = 'http://127.0.0.1:6120',
    this.orchardServiceAccountName = 'openci',
    this.orchardServiceAccountToken = '',
  });

  final String serverUrl;
  final String runsOnPattern;
  final String baseVmName;
  final String tailscaleApiKey;
  final String tailscaleTailnet;
  final String internalApiKey;
  final List<String> excludeIps;
  final String? sentryDsn;
  final int maxConcurrentJobs;

  factory ProcessorConfig.fromEnvironment() {
    String getRequired(String key) {
      final value = Platform.environment[key];
      if (value == null || value.isEmpty) {
        throw StateError('必要な環境変数 $key が設定されていません。');
      }
      return value;
    }

    final excludeIpsStr = Platform.environment['OPENCI_EXCLUDE_IPS'] ?? '';
    final excludeIpsList = excludeIpsStr.isNotEmpty
        ? excludeIpsStr.split(',').map((ip) => ip.trim()).toList()
        : <String>[];

    final maxConcurrentJobsStr =
        Platform.environment['OPENCI_MAX_CONCURRENT_JOBS'] ?? '3';
    final maxConcurrentJobs = int.tryParse(maxConcurrentJobsStr) ?? 3;

    final useOrchard =
        (Platform.environment['USE_ORCHARD'] ?? '').toLowerCase() == 'true' ||
        Platform.environment.containsKey('ORCHARD_API_URL');

    final tailscaleApiKey = useOrchard
        ? (Platform.environment['TAILSCALE_API_KEY'] ?? '')
        : getRequired('TAILSCALE_API_KEY');
    final tailscaleTailnet = useOrchard
        ? (Platform.environment['TAILSCALE_TAILNET'] ?? '')
        : getRequired('TAILSCALE_TAILNET');

    final orchardApiUrl =
        Platform.environment['ORCHARD_API_URL'] ??
        'https://orchard-controller:6120';
    var orchardServiceAccountName =
        Platform.environment['ORCHARD_SERVICE_ACCOUNT_NAME'] ?? 'openci';
    var orchardServiceAccountToken =
        Platform.environment['ORCHARD_SERVICE_ACCOUNT_TOKEN'] ?? '';

    if (orchardServiceAccountToken.isEmpty ||
        orchardServiceAccountToken.contains('10nv')) {
      final homeDir = Platform.environment['HOME'] ?? '';
      final orchardConfigFile = File('$homeDir/.orchard/orchard.yml');
      if (orchardConfigFile.existsSync()) {
        final content = orchardConfigFile.readAsStringSync();
        final nameMatch = RegExp(
          r'serviceAccountName:\s*(.+)',
        ).firstMatch(content);
        if (nameMatch != null) {
          orchardServiceAccountName = nameMatch.group(1)!.trim();
        }
        final tokenMatch = RegExp(
          r'serviceAccountToken:\s*(.+)',
        ).firstMatch(content);
        if (tokenMatch != null) {
          orchardServiceAccountToken = tokenMatch.group(1)!.trim();
        }
      }
    }

    return ProcessorConfig(
      serverUrl: getRequired('OPENCI_SERVER_URL'),
      runsOnPattern: getRequired('OPENCI_RUNS_ON_PATTERN'),
      baseVmName: getRequired('LUME_BASE_VM_NAME'),
      tailscaleApiKey: tailscaleApiKey,
      tailscaleTailnet: tailscaleTailnet,
      internalApiKey: getRequired('INTERNAL_API_KEY'),
      excludeIps: excludeIpsList,
      sentryDsn: Platform.environment['SENTRY_DSN'],
      maxConcurrentJobs: maxConcurrentJobs,
      useOrchard: useOrchard,
      orchardApiUrl: orchardApiUrl,
      orchardServiceAccountName: orchardServiceAccountName,
      orchardServiceAccountToken: orchardServiceAccountToken,
    );
  }

  final bool useOrchard;
  final String orchardApiUrl;
  final String orchardServiceAccountName;
  final String orchardServiceAccountToken;
}
