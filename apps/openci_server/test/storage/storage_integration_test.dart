import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:openci_server/settings/storage_settings.dart';
import 'package:openci_server/storage.dart';
import 'package:test/test.dart';

void main() {
  group('StorageManager Integration Tests with Local SeaweedFS', () {
    late StorageManager storage;
    const testBucket = 'openci-integration-test';
    bool isStorageReachable = false;

    setUpAll(() async {
      final baseSettings = loadStorageSettings();
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
        // 短いタイムアウト等で事前に疎通確認を試みる
        isStorageReachable = await storage.verifyConnection();
      } catch (_) {
        isStorageReachable = false;
      }
    });

    test(
      'Full lifecycle: verify, initialize, upload, download, and presigned url',
      () async {
        if (!isStorageReachable) {
          markTestSkipped('SeaweedFS (S3) is not reachable at the configured endpoint. Skipping integration test.');
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

        final response = await http.get(Uri.parse(resolvedUrl));
        expect(response.statusCode, equals(200));
        expect(response.body, equals(testContent));
      },
    );
  });
}

