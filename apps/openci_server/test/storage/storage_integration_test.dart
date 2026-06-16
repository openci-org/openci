import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:openci_server/environment_value/environment_value.dart';
import 'package:openci_server/storage.dart';
import 'package:test/test.dart';

void main() {
  group('StorageManager Integration Tests with Local SeaweedFS', () {
    late StorageManager storage;
    const testBucket = 'openci-integration-test';
    bool isStorageReachable = false;

    setUpAll(() async {
      final env = Map<String, String>.from(Platform.environment)
        ..putIfAbsent('DATABASE_URL', () => 'postgres://localhost:5432/openci')
        ..putIfAbsent(
          'SECRET_ENCRYPTION_KEY',
          () => 'dummy_secret_key_1234567890',
        );
      final baseSettings = EnvironmentValue.load(environment: env).storage;
      final settings = StorageSettings(
        endPoint: baseSettings.endPoint,
        port: baseSettings.port,
        useSSL: baseSettings.useSSL,
        accessKey: baseSettings.accessKey,
        secretKey: baseSettings.secretKey,
        bucket: testBucket,
      );

      storage = StorageManager(settings);

      try {
        isStorageReachable = await storage.verifyConnection();
      } catch (_) {
        isStorageReachable = false;
      }
    });

    test(
      'Full lifecycle: verify, initialize, upload, download, and presigned url',
      () async {
        if (!isStorageReachable) {
          markTestSkipped(
            'SeaweedFS (S3) is not reachable at the configured endpoint. Skipping integration test.',
          );
          return;
        }

        await storage.initialize();

        final testFileName =
            'integration_test_${DateTime.now().millisecondsSinceEpoch}.txt';
        final testContent = 'Hello, this is integration test content!';
        final uploadStream = Stream.value(
          Uint8List.fromList(utf8.encode(testContent)),
        );
        await storage.uploadObject(
          testFileName,
          uploadStream,
          size: testContent.length,
        );

        final downloadStream = await storage.downloadObject(testFileName);
        final downloadBytes = await downloadStream
            .expand((chunk) => chunk)
            .toList();
        final downloadedText = utf8.decode(downloadBytes);
        expect(downloadedText, equals(testContent));

        final presignedUrl = await storage.getPresignedUrl(testFileName);
        expect(presignedUrl, contains(testFileName));

        final resolvedUrl = presignedUrl.replaceAll(
          'seaweedfs:8000',
          'localhost:18000',
        );

        final http.Response response;
        try {
          response = await http
              .get(Uri.parse(resolvedUrl))
              .timeout(const Duration(seconds: 10));
        } on TimeoutException catch (e) {
          fail('HTTP request to download presigned URL timed out: $e');
        }
        expect(response.statusCode, equals(200));
        expect(response.body, equals(testContent));
      },
    );
  });
}
