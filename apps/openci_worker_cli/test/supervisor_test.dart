import 'dart:async';
import 'dart:io';

import 'package:openci_worker_cli/supervisor.dart';
import 'package:sentry/sentry.dart';
import 'package:test/test.dart';

void main() {
  group('Supervisor tests', () {
    final capturedEnvelopes = <SentryEnvelope>[];

    setUp(() async {
      capturedEnvelopes.clear();
      await Sentry.close();
      await Sentry.init((options) {
        options.dsn = 'https://public@sentry.example.com/1';
        options.transport = MockTransport(capturedEnvelopes);
      });
    });

    test(
      'runSupervised catches ProcessException and reports to Sentry',
      () async {
        final completer = Completer<void>();
        var callCount = 0;

        Future<Process> mockProcessStart(
          String executable,
          List<String> arguments, {
          String? workingDirectory,
          Map<String, String>? environment,
          bool includeParentEnvironment = true,
          bool runInShell = false,
          ProcessStartMode mode = ProcessStartMode.normal,
        }) async {
          callCount++;
          if (callCount == 1) {
            throw const ProcessException(
              'openci_worker',
              [],
              'No such file or directory',
            );
          }
          completer.complete();
          throw _StopLoopException();
        }

        try {
          await runSupervised(
            ['--supervised', 'arg1'],
            processStart: mockProcessStart,
            crashRestartDelay: Duration.zero,
          ).timeout(const Duration(seconds: 2));
        } catch (e) {
          expect(e, isA<_StopLoopException>());
        }

        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(callCount, equals(2));
        expect(capturedEnvelopes.length, equals(1));

        final envelope = capturedEnvelopes.first;
        expect(envelope.items, isNotEmpty);
        expect(envelope.items.first.header.type, equals('event'));
      },
    );
  });
}

class _StopLoopException implements Exception {}

class MockTransport extends Transport {
  final List<SentryEnvelope> capturedEvents;

  MockTransport(this.capturedEvents);

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    capturedEvents.add(envelope);
    return envelope.header.eventId;
  }
}
