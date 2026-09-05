import 'package:build_job_worker/build_job_worker.dart';
import 'package:test/test.dart';

void main() {
  group('Config', () {
    test('stores the supplied configuration', () {
      const config = Config(
        serverUrl: 'http://localhost:8080',
        internalApiKey: 'test-api-key',
        sentryDsn: 'https://public@example.com/1',
      );

      expect(config.serverUrl, 'http://localhost:8080');
      expect(config.internalApiKey, 'test-api-key');
      expect(config.sentryDsn, 'https://public@example.com/1');
    });

    test('does not require a Sentry DSN', () {
      const config = Config(
        serverUrl: 'http://localhost:8080',
        internalApiKey: 'test-api-key',
      );

      expect(config.sentryDsn, isNull);
    });
  });

  group('Config.fromEnvironment', () {
    const requiredEnvironment = {
      'OPENCI_SERVER_URL': 'http://localhost:8080',
      'INTERNAL_API_KEY': 'test-api-key',
    };

    test('reads the supplied environment', () {
      final config = Config.fromEnvironment(
        environment: {
          ...requiredEnvironment,
          'SENTRY_DSN': 'https://public@example.com/1',
        },
      );

      expect(config.serverUrl, 'http://localhost:8080');
      expect(config.internalApiKey, 'test-api-key');
      expect(config.sentryDsn, 'https://public@example.com/1');
    });

    test('accepts only the required variables without a build job ID', () {
      final config = Config.fromEnvironment(environment: requiredEnvironment);

      expect(config.serverUrl, 'http://localhost:8080');
      expect(config.internalApiKey, 'test-api-key');
      expect(config.sentryDsn, isNull);
    });

    for (final key in requiredEnvironment.keys) {
      test('rejects a missing $key', () {
        final environment = {...requiredEnvironment}..remove(key);

        expect(
          () => Config.fromEnvironment(environment: environment),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Required environment variable $key is not set.',
            ),
          ),
        );
      });

      test('rejects an empty $key', () {
        final environment = {...requiredEnvironment, key: ''};

        expect(
          () => Config.fromEnvironment(environment: environment),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Required environment variable $key is not set.',
            ),
          ),
        );
      });
    }
  });
}
