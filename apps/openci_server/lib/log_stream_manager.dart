import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:openci_server/storage.dart';

class LogStreamManager {
  static final LogStreamManager _instance = LogStreamManager._internal();
  factory LogStreamManager() => _instance;
  LogStreamManager._internal();

  final Map<String, List<String>> _buffers = {};
  final Map<String, StreamController<String>> _streams = {};

  void initSession(String runId) {
    _buffers.putIfAbsent(runId, () => []);
    _streams.putIfAbsent(
      runId,
      () => StreamController<String>.broadcast(),
    );
  }

  void appendLog(String runId, String message) {
    if (!_buffers.containsKey(runId)) {
      initSession(runId);
    }

    _buffers[runId]?.add(message);

    final controller = _streams[runId];
    if (controller != null && !controller.isClosed) {
      controller.add(message);
    }
  }

  Stream<String>? getStream(String runId) {
    return _streams[runId]?.stream;
  }

  List<String> getBuffer(String runId) {
    final buffer = _buffers[runId];
    if (buffer == null) return const [];
    return List.unmodifiable(buffer);
  }

  bool hasSession(String runId) {
    return _buffers.containsKey(runId);
  }

  Future<void> finalizeSession(String runId, StorageManager storage) async {
    try {
      final buffer = _buffers[runId];
      if (buffer != null && buffer.isNotEmpty) {
        final logText = '${buffer.join('\n')}\n';
        final bytes = Uint8List.fromList(utf8.encode(logText));
        final stream = Stream.value(bytes);

        await storage.uploadObject(
          'logs/$runId.log',
          stream,
          size: bytes.length,
        );
      }
    } finally {
      final controller = _streams[runId];
      if (controller != null) {
        await controller.close();
      }
      _streams.remove(runId);
      _buffers.remove(runId);
    }
  }
}
