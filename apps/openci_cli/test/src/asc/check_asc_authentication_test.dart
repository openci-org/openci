import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:genuineci_cli/src/asc/asc_authentication_status.dart';
import 'package:genuineci_cli/src/asc/check_asc_authentication.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _InputSink implements IOSink {
  bool closed = false;

  @override
  Future<void> close() async => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StatusProcess implements Process {
  _StatusProcess({
    String output = '{"authenticated":true}',
    int? code = 0,
    Stream<List<int>>? stdout,
    Stream<List<int>>? stderr,
  }) : stdout = stdout ?? Stream.value(utf8.encode(output)),
       stderr = stderr ?? const Stream.empty() {
    if (code != null) exited.complete(code);
  }

  final exited = Completer<int>();
  final signals = <ProcessSignal>[];

  @override
  final _InputSink stdin = _InputSink();

  @override
  final Stream<List<int>> stdout;

  @override
  final Stream<List<int>> stderr;

  @override
  Future<int> get exitCode => exited.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    signals.add(signal);
    if (!exited.isCompleted) exited.complete(-signal.signalNumber);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final executable = File('cached tools/asc');
  const appleId = "o'hara+ios@example.com";
  late _StatusProcess process;

  setUp(() => process = _StatusProcess());

  Future<AscAuthenticationStatus> check({
    Duration timeout = const Duration(seconds: 1),
  }) => checkAscAuthentication(
    executable,
    appleId,
    timeout: timeout,
    processStarter: (path, arguments) async {
      expect(path, executable.absolute.path);
      expect(arguments, [
        'web',
        'auth',
        'status',
        '--apple-id',
        appleId,
        '--output',
        'json',
      ]);
      return process;
    },
  );

  Matcher failsWith(AscAuthenticationFailure failure) => throwsA(
    isA<AscAuthenticationException>().having(
      (error) => error.failure,
      'failure',
      failure,
    ),
  );

  for (final authenticated in [true, false]) {
    test('uses authenticated=$authenticated even with exit code 0', () async {
      process = _StatusProcess(
        output: jsonEncode({
          'authenticated': authenticated,
          'appleId': appleId,
          'passwordStored': true,
          'providerId': 123,
          'publicProviderId': 'PUBLIC1234',
        }),
      );

      final status = await check();
      expect(status.authenticated, authenticated);
      expect(status.providerId, 123);
      expect(status.publicProviderId, 'PUBLIC1234');

      expect(process.stdin.closed, isTrue);
      expect(process.signals, isEmpty);
    });
  }

  for (final (fields, providerId, publicProviderId)
      in <(Map<String, Object?>, int?, String?)>[
        ({}, null, null),
        ({'providerId': null, 'publicProviderId': null}, null, null),
        ({'providerId': 123}, 123, null),
        ({'publicProviderId': 'PUBLIC1234'}, null, 'PUBLIC1234'),
        ({'publicProviderId': '  PUBLIC1234  '}, null, 'PUBLIC1234'),
        ({'publicProviderId': ''}, null, null),
        ({'publicProviderId': '   '}, null, null),
        ({'teamId': 'OTHER12345', 'developerTeamId': 'DEV1234567'}, null, null),
      ]) {
    test(
      'reads optional provider information: ${jsonEncode(fields)}',
      () async {
        process = _StatusProcess(
          output: jsonEncode({'authenticated': true, ...fields}),
        );

        final status = await check();

        expect(status.authenticated, isTrue);
        expect(status.providerId, providerId);
        expect(status.publicProviderId, publicProviderId);
      },
    );
  }

  for (final fields in <Map<String, Object>>[
    {'providerId': '123'},
    {'providerId': 123.0},
    {'providerId': 0},
    {'providerId': -1},
    {'providerId': true},
    {'providerId': <int>[]},
    {'publicProviderId': 123},
    {'publicProviderId': true},
    {'publicProviderId': <String>[]},
    {'publicProviderId': 'PUBLIC\u001b[31m'},
    {'publicProviderId': 'PUBLIC\nID'},
    {'publicProviderId': 'PUBLIC\u0085ID'},
  ]) {
    test(
      'rejects invalid provider information: ${jsonEncode(fields)}',
      () async {
        process = _StatusProcess(
          output: jsonEncode({'authenticated': true, ...fields}),
        );

        await expectLater(
          check(),
          failsWith(AscAuthenticationFailure.response),
        );
      },
    );
  }

  for (final output in [
    '',
    'not JSON',
    '{"authenticated":',
    '{"authenticated":true}\ntrailing output',
    'null',
    'true',
    '[]',
    '[{"authenticated":true}]',
    '{}',
    '{"authenticated":"true"}',
    '{"authenticated":1}',
    '{"authenticated":null}',
  ]) {
    test('rejects an invalid status: $output', () async {
      process = _StatusProcess(output: output);

      await expectLater(check(), failsWith(AscAuthenticationFailure.response));
    });
  }

  test('decodes UTF-8 after collecting separate output chunks', () async {
    final bytes = utf8.encode('{"authenticated":true,"extra":"日本語"}');
    process = _StatusProcess(
      stdout: Stream.fromIterable(bytes.map((byte) => [byte])),
    );

    expect((await check()).authenticated, isTrue);
  });

  test('rejects invalid UTF-8 output', () async {
    process = _StatusProcess(stdout: Stream.value([0xff]));

    await expectLater(check(), failsWith(AscAuthenticationFailure.response));
  });

  test('rejects oversized output even if it is valid JSON', () async {
    process = _StatusProcess(
      output: jsonEncode({'authenticated': true, 'extra': 'x' * (16 * 1024)}),
    );

    await expectLater(check(), failsWith(AscAuthenticationFailure.response));
  });

  for (final code in [1, -9]) {
    test('rejects authenticated=true when asc exits with $code', () async {
      process = _StatusProcess(code: code);

      await expectLater(check(), failsWith(AscAuthenticationFailure.execution));
    });
  }

  test('reports a startup failure without retaining its details', () async {
    await expectLater(
      checkAscAuthentication(
        executable,
        appleId,
        processStarter: (path, arguments) async =>
            throw ProcessException(path, arguments, 'private diagnostic'),
      ),
      failsWith(AscAuthenticationFailure.execution),
    );
  });

  for (final stdoutFails in [true, false]) {
    test(
      'stops the process after a stream error (stdout: $stdoutFails)',
      () async {
        final broken = Stream<List<int>>.error(
          const FileSystemException('private diagnostic'),
        );
        process = _StatusProcess(
          code: null,
          stdout: stdoutFails ? broken : null,
          stderr: stdoutFails ? null : broken,
        );

        await expectLater(
          check(),
          failsWith(AscAuthenticationFailure.execution),
        );

        expect(process.signals, [ProcessSignal.sigkill]);
        expect(await process.exitCode, -9);
        expect(process.stdin.closed, isTrue);
      },
    );
  }

  test('times out and releases output subscriptions', () async {
    final output = StreamController<List<int>>();
    final errors = StreamController<List<int>>();
    addTearDown(output.close);
    addTearDown(errors.close);
    process = _StatusProcess(
      code: null,
      stdout: output.stream,
      stderr: errors.stream,
    );

    await expectLater(
      check(timeout: const Duration(milliseconds: 20)),
      failsWith(AscAuthenticationFailure.timeout),
    );

    expect(process.signals, [ProcessSignal.sigkill]);
    expect(await process.exitCode, -9);
    expect(process.stdin.closed, isTrue);
    expect(output.hasListener, isFalse);
    expect(errors.hasListener, isFalse);
  });

  group('real subprocess', () {
    late Directory root;
    late File script;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('genuineci asc status ');
      script = File(p.join(root.path, 'asc'));
    });

    tearDown(() => root.delete(recursive: true));

    Future<void> writeScript(String body) async {
      await script.writeAsString('#!/bin/sh\n$body');
      final result = await Process.run('/bin/chmod', ['700', script.path]);
      expect(result.exitCode, 0);
    }

    for (final authenticated in [true, false]) {
      test('closes stdin, drains stderr, and reads $authenticated', () async {
        await writeScript('''
if IFS= read -r value; then exit 7; fi
i=0
while [ \$i -lt 8192 ]; do
  printf 'private status diagnostic\\n' >&2
  i=\$((i + 1))
done
printf '{"authenticated":$authenticated}\\n'
''');

        expect(
          (await checkAscAuthentication(script, appleId)).authenticated,
          authenticated,
        );
      });
    }

    test('terminates and reaps a real process on timeout', () async {
      await writeScript('exec /bin/sleep 30\n');
      Process? child;
      addTearDown(() => child?.kill(ProcessSignal.sigkill));

      await expectLater(
        checkAscAuthentication(
          script,
          appleId,
          timeout: const Duration(milliseconds: 100),
          processStarter: (path, arguments) async {
            child = await Process.start(path, arguments);
            return child!;
          },
        ),
        failsWith(AscAuthenticationFailure.timeout),
      );

      expect(await child!.exitCode, -9);
    });
  }, skip: Platform.isWindows);
}
