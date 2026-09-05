import 'dart:io';

import 'package:test/test.dart';

void main() {
  const environment = {
    'OPENCI_SERVER_URL': 'http://127.0.0.1:1',
    'INTERNAL_API_KEY': 'test-api-key',
    'ORCHARD_SERVICE_ACCOUNT_NAME': 'bootstrap-admin',
    'ORCHARD_SERVICE_ACCOUNT_TOKEN': 'test-orchard-token',
  };

  test('loads process environment and exits without processing jobs', () async {
    final result = await _runWorker(environment);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Build job worker configuration loaded.'));
    expect(result.stdout, contains('Job processing is not enabled yet.'));
    expect(result.stdout, isNot(contains(environment['INTERNAL_API_KEY'])));
    expect(
      result.stdout,
      isNot(contains(environment['ORCHARD_SERVICE_ACCOUNT_TOKEN'])),
    );
    expect(result.stderr, isEmpty);
  });

  for (final key in environment.keys) {
    test('exits with an error when $key is missing', () async {
      final result = await _runWorker({...environment}..remove(key));

      expect(result.exitCode, 1);
      expect(result.stdout, isEmpty);
      expect(
        result.stderr,
        contains('Required environment variable $key is not set.'),
      );
      expect(result.stderr, isNot(contains(environment['INTERNAL_API_KEY'])));
      expect(
        result.stderr,
        isNot(contains(environment['ORCHARD_SERVICE_ACCOUNT_TOKEN'])),
      );
    });
  }
}

Future<ProcessResult> _runWorker(Map<String, String> environment) {
  final processEnvironment = {...Platform.environment}
    ..remove('OPENCI_SERVER_URL')
    ..remove('INTERNAL_API_KEY')
    ..remove('ORCHARD_SERVICE_ACCOUNT_NAME')
    ..remove('ORCHARD_SERVICE_ACCOUNT_TOKEN')
    ..remove('SENTRY_DSN')
    ..addAll(environment);

  return Process.run(
    Platform.resolvedExecutable,
    ['run', 'bin/main.dart'],
    environment: processEnvironment,
    includeParentEnvironment: false,
  );
}
