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
    });

    test(
      'Full lifecycle: verify, initialize, upload, download, and presigned url',
      () async {
        final healthy = await storage.verifyConnection();
        if (!healthy) {
          print(
            'Skipping StorageManager integration test: SeaweedFS (S3) is not reachable.',
          );
          return;
        }

        // 1. Initialize bucket
        await storage.initialize();

        // 2. Upload object
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

        // 3. Download object
        final downloadStream = await storage.downloadObject(testFileName);
        final downloadBytes = await downloadStream
            .expand((chunk) => chunk)
            .toList();
        final downloadedText = utf8.decode(downloadBytes);
        expect(downloadedText, equals(testContent));

        // 4. Presigned URL test
        final presignedUrl = await storage.getPresignedUrl(testFileName);
        expect(presignedUrl, contains(testFileName));

        // Adjust endpoint if running outside the container network
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
