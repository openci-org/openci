import 'dart:async';
import 'dart:convert';

class LokiLogBuffer {
  LokiLogBuffer({
    required Future<void> Function(List<List<String>> values) sendBatch,
    required void Function(Object error) onError,
    int maxLines = 100,
    int maxBytes = 64 * 1024,
    Duration flushInterval = const Duration(milliseconds: 200),
  }) : assert(maxLines > 0),
       assert(maxBytes > 0),
       _sendBatch = sendBatch,
       _onError = onError,
       _maxLines = maxLines,
       _maxBytes = maxBytes,
       _flushInterval = flushInterval;

  final Future<void> Function(List<List<String>> values) _sendBatch;
  final void Function(Object error) _onError;
  final int _maxLines;
  final int _maxBytes;
  final Duration _flushInterval;

  List<List<String>> _values = [];
  int _bytes = 0;
  Timer? _timer;
  Future<void>? _sending;
  bool _failed = false;
  bool _closed = false;

  Future<void> add(String message) async {
    if (_closed) throw StateError('The log buffer is closed.');
    if (_failed) return;

    final timestamp = (DateTime.now().toUtc().microsecondsSinceEpoch * 1000)
        .toString();
    final bytes = utf8.encode(message).length;
    if (_values.isNotEmpty && _bytes + bytes > _maxBytes) {
      await flush();
      if (_failed) return;
    }

    _values.add([timestamp, message]);
    _bytes += bytes;
    if (_values.length >= _maxLines || _bytes >= _maxBytes) {
      // Pause the reader at the batch limit while a slow upload catches up.
      await flush();
    } else if (_values.length == 1) {
      _timer = Timer(_flushInterval, () => unawaited(flush()));
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;

    // Timer, full-buffer, and shutdown flushes share one upload at a time.
    while (_sending != null) {
      await _sending;
    }
    if (_values.isEmpty || _failed) return;

    final values = _values;
    _values = [];
    _bytes = 0;
    final sending = _send(values);
    _sending = sending;
    try {
      await sending;
    } finally {
      _sending = null;
    }
  }

  Future<void> _send(List<List<String>> values) async {
    try {
      await _sendBatch(values);
    } catch (error) {
      _failed = true;
      _values.clear();
      _bytes = 0;
      _timer?.cancel();
      _timer = null;
      _onError(error);
    }
  }

  Future<void> close() async {
    _closed = true;
    await flush();
  }
}
