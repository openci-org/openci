import 'dart:io';

import 'package:openci_server/environment_value/environment_value.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentValue.load Tests', () {
    final baseEnv = {
      'DATABASE_URL': 'postgres://test-db:5432/test',
      'SECRET_ENCRYPTION_KEY': 'some_secret_key_here_1234567890',
    };

    test('successfully loads with base env', () {
      final config = EnvironmentValue.load(environment: baseEnv);
      expect(config.databaseUrl, equals('postgres://test-db:5432/test'));
      expect(
        config.secretEncryptionKey,
        equals('some_secret_key_here_1234567890'),
      );
      expect(config.host, equals(InternetAddress.loopbackIPv4));
      expect(config.port, equals(8080));
      expect(config.appEnv, equals('development'));
    });

    test('throws StateError if DATABASE_URL is missing', () {
      final env = Map<String, String>.from(baseEnv)..remove('DATABASE_URL');
      expect(() => EnvironmentValue.load(environment: env), throwsStateError);
    });

    test('throws StateError if SECRET_ENCRYPTION_KEY is missing', () {
      final env = Map<String, String>.from(baseEnv)
        ..remove('SECRET_ENCRYPTION_KEY');
      expect(() => EnvironmentValue.load(environment: env), throwsStateError);
    });

    test('parses HOST and PORT correctly', () {
      final env = {
        ...baseEnv,
        'HOST': 'any',
        'PORT': '9090',
      };
      final config = EnvironmentValue.load(environment: env);
      expect(config.host, equals(InternetAddress.anyIPv4));
      expect(config.port, equals(9090));
    });

    test('falls back to 8080 on invalid port', () {
      final env = {
        ...baseEnv,
        'PORT': 'invalid',
      };
      final config = EnvironmentValue.load(environment: env);
      expect(config.port, equals(8080));
    });

    test('parses storage environment variables correctly', () {
      final env = {
        ...baseEnv,
        'S3_ENDPOINT': 'https://my-s3:9000',
        'S3_ACCESS_KEY': 'my-access',
        'S3_SECRET_KEY': 'my-secret',
        'S3_BUCKET': 'my-bucket',
      };
      final config = EnvironmentValue.load(environment: env);
      expect(config.storage.endPoint, equals('my-s3'));
      expect(config.storage.port, equals(9000));
      expect(config.storage.useSSL, isTrue);
      expect(config.storage.accessKey, equals('my-access'));
      expect(config.storage.secretKey, equals('my-secret'));
      expect(config.storage.bucket, equals('my-bucket'));
    });

    test('falls back to default storage settings when empty', () {
      final config = EnvironmentValue.load(environment: baseEnv);
      expect(config.storage.endPoint, equals('localhost'));
      expect(config.storage.port, equals(18000));
      expect(config.storage.useSSL, isFalse);
      expect(config.storage.accessKey, equals('dummy_access_key'));
      expect(config.storage.secretKey, equals('dummy_secret_key'));
      expect(config.storage.bucket, equals('openci'));
    });

    test('parses scheme-less S3_ENDPOINT correctly', () {
      final env = {
        ...baseEnv,
        'S3_ENDPOINT': 'localhost:9000',
      };
      final config = EnvironmentValue.load(environment: env);
      expect(config.storage.endPoint, equals('localhost'));
      expect(config.storage.port, equals(9000));
      expect(config.storage.useSSL, isFalse);
    });

    test('throws StateError on invalid S3_ENDPOINT', () {
      final env = {
        ...baseEnv,
        'S3_ENDPOINT': '   ',
      };
      expect(
        () => EnvironmentValue.load(environment: env),
        throwsA(isA<StateError>()),
      );
    });
  });
}
