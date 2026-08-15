import 'dart:io';

class ProcessorConfig {
  const ProcessorConfig({
    required this.databaseUrl,
    required this.githubApiBaseUrl,
    required this.githubAppId,
    required this.githubPrivateKeyPath,
    this.sentryDsn,
    this.pollInterval = const Duration(seconds: 1),
  });

  factory ProcessorConfig.fromEnvironment({
    Map<String, String>? environment,
  }) {
    final env = environment ?? Platform.environment;

    final databaseUrl = env['DATABASE_URL'];
    if (databaseUrl == null || databaseUrl.isEmpty) {
      throw StateError('DATABASE_URL environment variable is required.');
    }

    final githubApiBaseUrl = env['GITHUB_API_BASE_URL'];
    if (githubApiBaseUrl == null || githubApiBaseUrl.isEmpty) {
      throw StateError(
        'GITHUB_API_BASE_URL environment variable is required.',
      );
    }

    final githubAppId = env['GITHUB_APP_ID'];
    if (githubAppId == null || githubAppId.isEmpty) {
      throw StateError('GITHUB_APP_ID environment variable is required.');
    }

    final githubPrivateKeyPath = env['GITHUB_PRIVATE_KEY_PATH'];
    if (githubPrivateKeyPath == null || githubPrivateKeyPath.isEmpty) {
      throw StateError(
        'GITHUB_PRIVATE_KEY_PATH environment variable is required.',
      );
    }

    final pollIntervalMs = int.tryParse(env['POLL_INTERVAL_MS'] ?? '1000') ?? 1000;

    return ProcessorConfig(
      databaseUrl: databaseUrl,
      githubApiBaseUrl: githubApiBaseUrl,
      githubAppId: githubAppId,
      githubPrivateKeyPath: githubPrivateKeyPath,
      sentryDsn: env['SENTRY_DSN'],
      pollInterval: Duration(milliseconds: pollIntervalMs),
    );
  }

  final String databaseUrl;
  final String githubApiBaseUrl;
  final String githubAppId;
  final String githubPrivateKeyPath;
  final String? sentryDsn;
  final Duration pollInterval;
}
