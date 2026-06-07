import 'dart:typed_data';

import 'package:minio/minio.dart';
import 'package:openci_server/settings/storage_settings.dart';

class StorageManager {
  final Minio _client;
  final String _defaultBucket;

  StorageManager(StorageSettings settings, {Minio? client})
    : _client =
          client ??
          Minio(
            endPoint: settings.endPoint,
            port: settings.port,
            useSSL: settings.useSSL,
            accessKey: settings.accessKey,
            secretKey: settings.secretKey,
          ),
      _defaultBucket = settings.bucket;

  Future<void> initialize() async {
    final exists = await _client.bucketExists(_defaultBucket);
    if (!exists) {
      await _client.makeBucket(_defaultBucket);
    }
  }

  Future<void> uploadObject(
    String objectName,
    Stream<Uint8List> data, {
    int? size,
    String? bucket,
  }) async {
    final targetBucket = bucket ?? _defaultBucket;
    await _client.putObject(targetBucket, objectName, data, size: size);
  }

  Future<Stream<List<int>>> downloadObject(
    String objectName, {
    String? bucket,
  }) async {
    final targetBucket = bucket ?? _defaultBucket;
    return await _client.getObject(targetBucket, objectName);
  }

  Future<String> getPresignedUrl(
    String objectName, {
    Duration expires = const Duration(hours: 1),
    String? bucket,
  }) async {
    final targetBucket = bucket ?? _defaultBucket;
    return await _client.presignedGetObject(
      targetBucket,
      objectName,
      expires: expires.inSeconds,
    );
  }

  Future<bool> verifyConnection() async {
    try {
      await _client.bucketExists(_defaultBucket);
      return true;
    } catch (_) {
      return false;
    }
  }
}
