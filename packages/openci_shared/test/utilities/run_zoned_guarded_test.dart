import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';
import 'package:test/test.dart';

class _RecordingStderr implements Stdout {
  final lines = <String>[];

  @override
  void writeln([Object? object = '']) => lines.add('$object');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('awaits successful work without terminating the process', () async {
    final work = Completer<void>();
    var finished = false;
    final exitCodes = <int>[];
    final future = genuineCIRunZonedGuarded(() async {
      await work.future;
      finished = true;
    }, exitProcess: exitCodes.add);

    expect(finished, isFalse);
    work.complete();
    await future;
    expect(finished, isTrue);
    expect(exitCodes, isEmpty);
  });

  for (final mode in ['synchronous', 'asynchronous', 'unawaited']) {
    test('reports $mode errors before terminating with exit code 1', () async {
      final events = <SentryEvent>[];
      var networkRequests = 0;
      final client = MockClient((_) async {
        networkRequests++;
        return http.Response('', 503);
      });
      addTearDown(client.close);
      await Sentry.init((options) {
        options.dsn = 'https://public@sentry.example.test/1';
        options.debug = false;
        options.httpClient = client;
        for (final integration in options.integrations) {
          options.removeIntegration(integration);
        }
        options.beforeSend = (event, hint) async {
          await Future<void>.delayed(Duration.zero);
          events.add(event);
          return null;
        };
      });
      addTearDown(Sentry.close);

      final error = StateError('fatal $mode error');
      final stack = StackTrace.fromString('original guarded stack');
      final output = _RecordingStderr();
      final exited = Completer<int>();

      Future<void> body() {
        if (mode == 'synchronous') Error.throwWithStackTrace(error, stack);
        if (mode == 'asynchronous') {
          return Future<void>.delayed(
            Duration.zero,
            () => Error.throwWithStackTrace(error, stack),
          );
        }
        scheduleMicrotask(() => Error.throwWithStackTrace(error, stack));
        return Future<void>.value();
      }

      IOOverrides.runZoned(
        () => unawaited(
          genuineCIRunZonedGuarded(
            body,
            exitProcess: (code) {
              expect(events, hasLength(1));
              exited.complete(code);
            },
          ),
        ),
        stderr: () => output,
      );

      expect(await exited.future.timeout(const Duration(seconds: 5)), 1);
      expect(events.single.throwable, same(error));
      expect(output.lines, [
        'FATAL UNCAUGHT ERROR: $error',
        stack.toString(),
      ]);
      expect(networkRequests, 0);
    });
  }
}
