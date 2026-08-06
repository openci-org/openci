import 'dart:io';

class ProcessorConfig {
  ProcessorConfig({
    required this.serverUrl,
    required this.runsOnPattern,
    required this.baseVmName,
    required this.internalApiKey,
    this.sentryDsn,
    this.maxConcurrentJobs = 3,
    this.orchardApiUrl = 'https://orchard-controller:6120',
    this.orchardServiceAccountName = 'openci',
    this.orchardServiceAccountToken = '',
    this.vmPrepareTimeoutMinutes = 15,
  });

  final String serverUrl;
  final String runsOnPattern;
  final String baseVmName;
  final String internalApiKey;
  final String? sentryDsn;
  final int maxConcurrentJobs;

  final String orchardApiUrl;
  final String orchardServiceAccountName;
  final String orchardServiceAccountToken;
  final int vmPrepareTimeoutMinutes;

  factory ProcessorConfig.fromEnvironment() {
    String getRequired(String key) {
      final value = Platform.environment[key];
      if (value == null || value.isEmpty) {
        throw StateError('必要な環境変数 $key が設定されていません。');
      }
      return value;
    }

    final maxConcurrentJobsStr =
        Platform.environment['OPENCI_MAX_CONCURRENT_JOBS'] ?? '2';
    final maxConcurrentJobs = int.tryParse(maxConcurrentJobsStr) ?? 2;

    final vmPrepareTimeoutStr =
        Platform.environment['OPENCI_VM_PREPARE_TIMEOUT_MINUTES'] ?? '15';
    final vmPrepareTimeoutMinutes = int.tryParse(vmPrepareTimeoutStr) ?? 15;

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
      baseVmName:
          Platform.environment['BASE_VM_NAME'] ??
          Platform.environment['OPENCI_BASE_VM_NAME'] ??
          'tahoe-base',
      internalApiKey: getRequired('INTERNAL_API_KEY'),
      sentryDsn: Platform.environment['SENTRY_DSN'],
      maxConcurrentJobs: maxConcurrentJobs,
      orchardApiUrl: orchardApiUrl,
      orchardServiceAccountName: orchardServiceAccountName,
      orchardServiceAccountToken: orchardServiceAccountToken,
      vmPrepareTimeoutMinutes: vmPrepareTimeoutMinutes,
    );
  }
}
