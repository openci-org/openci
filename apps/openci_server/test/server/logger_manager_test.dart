import 'dart:convert';
import 'dart:typed_data';

import 'package:openci_server/logger_manager.dart';
import 'package:test/test.dart';

import '../storage/fake_storage.dart';

void main() {
  group('LogStreamManager Unit Tests', () {
    late LogStreamManager manager;
    late FakeStorageManager storage;

    setUp(() {
      manager = LogStreamManager();
      storage = FakeStorageManager();
    });

    test(
      'Session lifecycle (init, append, buffer, hasSession, finalize)',
      () async {
        final runId = 'test-lifecycle-${DateTime.now().millisecondsSinceEpoch}';

        expect(manager.hasSession(runId), isFalse);
        expect(manager.getBuffer(runId), isEmpty);

        manager.initSession(runId);
        expect(manager.hasSession(runId), isTrue);

        manager.appendLog(runId, 'First log line');
        manager.appendLog(runId, 'Second log line');

        final buffer = manager.getBuffer(runId);
        expect(buffer, equals(['First log line', 'Second log line']));

        await manager.finalizeSession(runId, storage);

        expect(manager.hasSession(runId), isFalse);
        expect(manager.getBuffer(runId), isEmpty);

        final savedData = await storage.downloadObject('logs/$runId.log');
        final savedBytes = await savedData.expand((c) => c).toList();
        final savedText = utf8.decode(savedBytes);
        expect(savedText, equals("First log line\nSecond log line\n"));
      },
    );

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
      await manager.finalizeSession(runId, storage);
    });

    test('Auto session initialization on append (Failsafe)', () async {
      final runId = 'test-failsafe-${DateTime.now().millisecondsSinceEpoch}';

      manager.appendLog(runId, 'Auto initialized log');

      expect(manager.hasSession(runId), isTrue);
      expect(manager.getBuffer(runId), equals(['Auto initialized log']));

      await manager.finalizeSession(runId, storage);
    });

    test('getBuffer returns an unmodifiable list', () async {
      final runId =
          'test-unmodifiable-${DateTime.now().millisecondsSinceEpoch}';
      manager.initSession(runId);
      manager.appendLog(runId, 'Log line');

      final buffer = manager.getBuffer(runId);
      expect(buffer, equals(['Log line']));

      expect(() => buffer.add('Mutated log line'), throwsUnsupportedError);
      expect(() => buffer.clear(), throwsUnsupportedError);

      final intactBuffer = manager.getBuffer(runId);
      expect(intactBuffer, equals(['Log line']));

      await manager.finalizeSession(runId, storage);
    });

    test(
      'finalizeSession cleans up memory even when uploadObject throws',
      () async {
        final runId =
            'test-upload-fail-${DateTime.now().millisecondsSinceEpoch}';
        manager.initSession(runId);
        manager.appendLog(runId, 'Log line 1');

        final failingStorage = FailingStorageManager();

        await expectLater(
          manager.finalizeSession(runId, failingStorage),
          throwsA(isA<Exception>()),
        );

        expect(manager.hasSession(runId), isFalse);
        expect(manager.getBuffer(runId), isEmpty);
      },
    );
  });
}

class FailingStorageManager extends FakeStorageManager {
  @override
  Future<void> uploadObject(
    String objectName,
    Stream<Uint8List> data, {
    int? size,
    String? bucket,
  }) async {
    throw Exception('Upload failed');
  }
}
