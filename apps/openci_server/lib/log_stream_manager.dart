import 'dart:async';

class LogStreamManager {
  static final LogStreamManager _instance = LogStreamManager._internal();
  factory LogStreamManager() => _instance;
  LogStreamManager._internal();

  final Map<String, StreamController<String>> _streams = {};

  void initSession(String runId) {
    _streams.putIfAbsent(
      runId,
      () => StreamController<String>.broadcast(),
    );
  }

  void appendLog(String runId, String message) {
    if (!_streams.containsKey(runId)) {
      initSession(runId);
    }

    final controller = _streams[runId];
    if (controller != null && !controller.isClosed) {
      controller.add(message);
    }
  }

  Stream<String>? getStream(String runId) {
    return _streams[runId]?.stream;
  }

  Future<void> finalizeSession(String runId) async {
    final controller = _streams[runId];
    if (controller != null) {
      await controller.close();
    }
    _streams.remove(runId);
  }
}
