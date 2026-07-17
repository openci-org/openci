import 'dart:io';

class ProcessorConfig {
  ProcessorConfig({
    required this.serverUrl,
    required this.runsOnPattern,
    required this.baseInstanceName,
    required this.incusApiUrl,
    required this.internalApiKey,
    this.sentryDsn,
    this.maxConcurrentJobs = 3,
  });

  final String serverUrl;
  final String runsOnPattern;
  final String baseInstanceName;
  final String incusApiUrl;
  final String internalApiKey;
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

    final maxConcurrentJobsStr =
        Platform.environment['OPENCI_MAX_CONCURRENT_JOBS'] ?? '3';
    final maxConcurrentJobs = int.tryParse(maxConcurrentJobsStr) ?? 3;

    return ProcessorConfig(
      serverUrl: getRequired('OPENCI_SERVER_URL'),
      runsOnPattern: getRequired('OPENCI_RUNS_ON_PATTERN'),
      baseInstanceName: getRequired('INCUS_BASE_INSTANCE'),
      incusApiUrl: getRequired('INCUS_API_URL'),
      internalApiKey: getRequired('INTERNAL_API_KEY'),
      sentryDsn: Platform.environment['SENTRY_DSN'],
      maxConcurrentJobs: maxConcurrentJobs,
    );
  }
}
