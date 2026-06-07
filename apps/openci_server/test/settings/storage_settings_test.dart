import 'package:openci_server/settings/storage_settings.dart';
import 'package:test/test.dart';

void main() {
  group('loadStorageSettings Tests', () {
    test('parses storage environment variables correctly', () {
      final settings = loadStorageSettings(
        environment: {
          'S3_ENDPOINT': 'https://my-s3:9000',
          'S3_ACCESS_KEY': 'my-access',
          'S3_SECRET_KEY': 'my-secret',
          'S3_BUCKET': 'my-bucket',
        },
      );
      expect(settings.endPoint, equals('my-s3'));
      expect(settings.port, equals(9000));
      expect(settings.useSSL, isTrue);
      expect(settings.accessKey, equals('my-access'));
      expect(settings.secretKey, equals('my-secret'));
      expect(settings.bucket, equals('my-bucket'));
    });

    test('falls back to default settings when environment is empty', () {
      final settings = loadStorageSettings(environment: {});
      expect(settings.endPoint, equals('localhost'));
      expect(settings.port, equals(18000));
      expect(settings.useSSL, isFalse);
      expect(settings.accessKey, equals('dummy_access_key'));
      expect(settings.secretKey, equals('dummy_secret_key'));
      expect(settings.bucket, equals('openci'));
    });
    test('parses scheme-less S3_ENDPOINT correctly', () {
      final settings = loadStorageSettings(
        environment: {
          'S3_ENDPOINT': 'localhost:9000',
        },
      );
      expect(settings.endPoint, equals('localhost'));
      expect(settings.port, equals(9000));
      expect(settings.useSSL, isFalse);
    });

    test('throws StateError on invalid S3_ENDPOINT', () {
      expect(
        () => loadStorageSettings(
          environment: {
            'S3_ENDPOINT': '   ',
          },
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
