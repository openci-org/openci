import 'dart:io';

import 'package:openci_dart_functions/src/config.dart';
import 'package:test/test.dart';

void main() {
  const requiredEnvironment = {
    'OPENCI_SERVER_URL': 'https://ci.example.test/api',
    'INTERNAL_API_KEY': 'planner-test-key',
  };

  test('uses the process environment when no environment is supplied', () {
    final environment = Platform.environment;
    for (final key in requiredEnvironment.keys) {
      if (environment[key] == null || environment[key]!.isEmpty) {
        expect(
          Config.fromEnvironment,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Required environment variable $key is not set.',
            ),
          ),
        );
        return;
      }
    }

    final config = Config.fromEnvironment();
    expect(config.serverUrl == environment['OPENCI_SERVER_URL'], isTrue);
    expect(config.internalApiKey == environment['INTERNAL_API_KEY'], isTrue);
    expect(config.sentryDsn == environment['SENTRY_DSN'], isTrue);
  });

  test('loads required settings without requiring Sentry', () {
    final config = Config.fromEnvironment(environment: requiredEnvironment);

    expect(config.serverUrl, 'https://ci.example.test/api');
    expect(config.internalApiKey, 'planner-test-key');
    expect(config.sentryDsn, isNull);
  });

  test('loads the optional Sentry DSN', () {
    final config = Config.fromEnvironment(
      environment: {
        ...requiredEnvironment,
        'SENTRY_DSN': 'https://public@sentry.example.test/1',
      },
    );

    expect(config.sentryDsn, 'https://public@sentry.example.test/1');
  });

  test('does not expose the internal API key in diagnostic output', () {
    final config = Config.fromEnvironment(environment: requiredEnvironment);

    expect(config.toString(), isNot(contains('planner-test-key')));
  });

  for (final key in requiredEnvironment.keys) {
    for (final value in [null, '']) {
      test('rejects a missing or empty $key: $value', () {
        final environment = {...requiredEnvironment}..remove(key);
        if (value != null) environment[key] = value;

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
  }
}
