import 'dart:async';

import 'package:openci_server/log_stream_manager.dart';
import 'package:test/test.dart';

void main() {
  group('LogStreamManager Unit Tests', () {
    late LogStreamManager manager;

    setUp(() {
      manager = LogStreamManager();
    });

    test('Real-time streaming via Broadcast Stream', () async {
      final runId = 'test-stream-${DateTime.now().millisecondsSinceEpoch}';
      manager.initSession(runId);

      final receivedLogs = <String>[];
      final stream = manager.getStream(runId);
      expect(stream, isNotNull);

      final subscription = stream!.listen((msg) {
        receivedLogs.add(msg);
      });

      manager.appendLog(runId, 'Streaming log 1');
      manager.appendLog(runId, 'Streaming log 2');

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs, equals(['Streaming log 1', 'Streaming log 2']));

      await subscription.cancel();
      await manager.finalizeSession(runId);

      expect(manager.getStream(runId), isNull);
    });

    test('Auto session initialization on append (Failsafe)', () async {
      final runId = 'test-failsafe-${DateTime.now().millisecondsSinceEpoch}';

      final receivedLogs = <String>[];
      manager.appendLog(runId, 'Auto initialized log');

      final stream = manager.getStream(runId);
      expect(stream, isNotNull);

      final subscription = stream!.listen((msg) {
        receivedLogs.add(msg);
      });

      manager.appendLog(runId, 'Next log');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(receivedLogs, equals(['Next log']));

      await subscription.cancel();
      await manager.finalizeSession(runId);
    });
  });
}
