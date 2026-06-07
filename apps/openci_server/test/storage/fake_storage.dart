import 'dart:typed_data';
import 'package:openci_server/storage.dart';

class FakeStorageManager implements StorageManager {
  bool healthy = true;
  final Map<String, List<int>> storage = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> uploadObject(
    String objectName,
    Stream<Uint8List> data, {
    int? size,
    String? bucket,
  }) async {
    final bytes = await data.expand((chunk) => chunk).toList();
    storage[objectName] = bytes;
  }

  @override
  Future<Stream<List<int>>> downloadObject(
    String objectName, {
    String? bucket,
  }) async {
    final data = storage[objectName];
    if (data == null) throw Exception('Object not found');
    return Stream.value(data);
  }

  @override
  Future<String> getPresignedUrl(
    String objectName, {
    Duration expires = const Duration(hours: 1),
    String? bucket,
  }) async {
    return 'http://fake-storage/$objectName';
  }

  @override
  Future<bool> verifyConnection() async {
    return healthy;
  }
}
