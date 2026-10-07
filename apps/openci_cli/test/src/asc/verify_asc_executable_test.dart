import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:genuineci_cli/src/asc/asc_release.dart';
import 'package:genuineci_cli/src/asc/verify_asc_executable.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _InputSink implements IOSink {
  bool closed = false;

  @override
  Future<void> close() async => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VersionProcess implements Process {
  _VersionProcess({
    String output = '$ascVersion\n',
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
  const fixture = 'verified asc fixture';
  final checksum = sha256.convert(utf8.encode(fixture)).toString();
  late Directory root;
  late File executable;
  late _VersionProcess process;
  late List<String> executedPaths;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('genuineci asc verification ');
    executable = await File(p.join(root.path, 'asc')).writeAsString(fixture);
    process = _VersionProcess();
    executedPaths = [];
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<void> verify({
    File? file,
    Duration timeout = const Duration(seconds: 1),
  }) => verifyAscExecutable(
    file ?? executable,
    expectedChecksum: checksum,
    timeout: timeout,
    processStarter: (path, arguments) async {
      executedPaths.add(path);
      expect(p.isAbsolute(path), isTrue);
      expect(arguments, ['version']);
      return process;
    },
  );

  Matcher failsWith(AscVerificationFailure failure) => throwsA(
    isA<AscVerificationException>().having(
      (error) => error.failure,
      'failure',
      failure,
    ),
  );

  for (final output in [
    '$ascVersion\n',
    '$ascVersion (commit: 8d16495, date: 2026-10-06T07:54:13+09:00)\n',
  ]) {
    test('accepts the pinned version output: ${output.trim()}', () async {
      process = _VersionProcess(output: output);

      await verify();

      expect(executedPaths, [executable.absolute.path]);
      expect(process.stdin.closed, isTrue);
      expect(process.signals, isEmpty);
    });
  }

  test('uses an absolute path even when given a relative file', () async {
    final relative = File(p.relative(executable.path));

    await verify(file: relative);

    expect(executedPaths, [relative.absolute.path]);
  });

  test('rejects an altered cache file before starting a process', () async {
    await executable.writeAsString('changed after installation');

    await expectLater(verify(), failsWith(AscVerificationFailure.checksum));

    expect(executedPaths, isEmpty);
    expect(await executable.readAsString(), 'changed after installation');
  });

  test('uses the pinned release checksum by default', () async {
    await expectLater(
      verifyAscExecutable(
        executable,
        processStarter: (_, _) async => fail('Unverified binary must not run'),
      ),
      failsWith(AscVerificationFailure.checksum),
    );
  });

  for (final directory in [false, true]) {
    test(
      'rejects a ${directory ? 'directory' : 'missing file'} before execution',
      () async {
        await executable.delete();
        if (directory) await Directory(executable.path).create();

        await expectLater(verify(), throwsA(isA<FileSystemException>()));

        expect(executedPaths, isEmpty);
      },
    );
  }

  test(
    'rejects a symlink even when its target has the expected checksum',
    () async {
      final target = await executable.rename(p.join(root.path, 'target'));
      await Link(executable.path).create(target.path);

      await expectLater(verify(), throwsA(isA<FileSystemException>()));

      expect(executedPaths, isEmpty);
    },
    skip: Platform.isWindows,
  );

  for (final output in [
    '',
    '5.10.0',
    '5.11.00',
    '$ascVersion-dev',
    'v$ascVersion',
    '$ascVersion unexpected text',
    '$ascVersion\nextra output',
    'asc version $ascVersion',
  ]) {
    test(
      'rejects an unexpected version output: ${jsonEncode(output)}',
      () async {
        process = _VersionProcess(output: output);

        await expectLater(verify(), failsWith(AscVerificationFailure.version));

        expect(process.signals, isEmpty);
      },
    );
  }

  test('rejects invalid UTF-8 output', () async {
    process = _VersionProcess(stdout: Stream.value([0xff]));

    await expectLater(verify(), failsWith(AscVerificationFailure.version));
  });

  test('limits retained output and rejects an oversized response', () async {
    process = _VersionProcess(
      stdout: Stream.fromIterable([
        utf8.encode('$ascVersion ('),
        List.filled(4096, 97),
        utf8.encode(')\n'),
      ]),
    );

    await expectLater(verify(), failsWith(AscVerificationFailure.version));
  });

  for (final code in [1, -9]) {
    test(
      'requires exit code 0 even when the version matches (exit $code)',
      () async {
        process = _VersionProcess(code: code);

        await expectLater(
          verify(),
          failsWith(AscVerificationFailure.execution),
        );
      },
    );
  }

  test('reports a failure to start the executable', () async {
    await expectLater(
      verifyAscExecutable(
        executable,
        expectedChecksum: checksum,
        processStarter: (path, arguments) async =>
            throw ProcessException(path, arguments, 'permission denied'),
      ),
      failsWith(AscVerificationFailure.execution),
    );
  });

  for (final errorOnStdout in [true, false]) {
    test(
      'stops a process after an output read error (stdout: $errorOnStdout)',
      () async {
        final broken = Stream<List<int>>.error(
          const FileSystemException('pipe failed'),
        );
        process = _VersionProcess(
          code: null,
          stdout: errorOnStdout ? broken : null,
          stderr: errorOnStdout ? null : broken,
        );

        await expectLater(
          verify(),
          failsWith(AscVerificationFailure.execution),
        );

        expect(process.signals, [ProcessSignal.sigkill]);
        expect(await process.exitCode, -9);
        expect(process.stdin.closed, isTrue);
      },
    );
  }

  for (final exited in [true, false]) {
    test(
      'times out and cancels open output streams (exited: $exited)',
      () async {
        final output = StreamController<List<int>>();
        final errors = StreamController<List<int>>();
        addTearDown(output.close);
        addTearDown(errors.close);
        process = _VersionProcess(
          code: exited ? 0 : null,
          stdout: output.stream,
          stderr: errors.stream,
        );

        await expectLater(
          verify(timeout: const Duration(milliseconds: 20)),
          failsWith(AscVerificationFailure.timeout),
        );

        expect(process.signals, [ProcessSignal.sigkill]);
        expect(await process.exitCode, exited ? 0 : -9);
        expect(process.stdin.closed, isTrue);
        expect(output.hasListener, isFalse);
        expect(errors.hasListener, isFalse);
      },
    );
  }

  group('real subprocess', () {
    Future<String> writeScript(String script) async {
      await executable.writeAsString(script);
      final result = await Process.run('/bin/chmod', ['700', executable.path]);
      expect(result.exitCode, 0);
      return sha256.convert(utf8.encode(script)).toString();
    }

    test('runs a verified executable and drains stderr', () async {
      final expectedChecksum = await writeScript('''#!/bin/sh
printf '$ascVersion (commit: test, date: test)\\n'
i=0
while [ \$i -lt 8192 ]; do
  printf 'version diagnostic\\n' >&2
  i=\$((i + 1))
done
''');

      await verifyAscExecutable(executable, expectedChecksum: expectedChecksum);
    });

    test('terminates and reaps a real process on timeout', () async {
      final expectedChecksum = await writeScript(
        '#!/bin/sh\nexec /bin/sleep 30\n',
      );
      Process? child;
      addTearDown(() => child?.kill(ProcessSignal.sigkill));

      await expectLater(
        verifyAscExecutable(
          executable,
          expectedChecksum: expectedChecksum,
          timeout: const Duration(milliseconds: 100),
          processStarter: (path, arguments) async {
            child = await Process.start(path, arguments);
            return child!;
          },
        ),
        failsWith(AscVerificationFailure.timeout),
      );

      expect(await child!.exitCode, -9);
    });

    test('reports a file without execute permission', () async {
      await expectLater(
        verifyAscExecutable(executable, expectedChecksum: checksum),
        failsWith(AscVerificationFailure.execution),
      );
    });
  }, skip: Platform.isWindows);
}
