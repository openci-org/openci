import 'package:github_webhook_processor/github_webhook_processor.dart';
import 'package:test/test.dart';

void main() {
  group('ProcessorConfig', () {
    test('parses environment correctly', () {
      final config = ProcessorConfig.fromEnvironment(
        environment: {
          'DATABASE_URL': 'postgres://user:pass@localhost:5432/db',
          'GITHUB_API_BASE_URL': 'https://api.github.com',
          'GITHUB_APP_ID': '12345',
          'GITHUB_PRIVATE_KEY_PATH': '/path/to/key.pem',
          'SENTRY_DSN': 'https://key@sentry.io/123',
        },
      );

      expect(config.databaseUrl, 'postgres://user:pass@localhost:5432/db');
      expect(config.githubApiBaseUrl, 'https://api.github.com');
      expect(config.githubAppId, '12345');
      expect(config.githubPrivateKeyPath, '/path/to/key.pem');
      expect(config.sentryDsn, 'https://key@sentry.io/123');
      expect(config.pollInterval, const Duration(seconds: 1));
    });

    test('throws StateError when required env vars are missing', () {
      expect(
        () => ProcessorConfig.fromEnvironment(environment: {}),
        throwsStateError,
      );

      expect(
        () => ProcessorConfig.fromEnvironment(
          environment: {
            'DATABASE_URL': 'postgres://...',
          },
        ),
        throwsStateError,
      );
    });
  });
}
