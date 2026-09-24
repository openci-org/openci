import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _timeout = Duration(seconds: 15);

void main() {
  if (Platform.isWindows) {
    test('requires POSIX process groups', () {}, skip: 'POSIX only');
    return;
  }

  late _DevStartFixture fixture;

  setUp(() async => fixture = await _DevStartFixture.create());
  tearDown(() async => fixture.dispose());

  test('SIGINT to the CLI process group stops Orchard and Compose', () async {
    await fixture.start();
    await fixture.waitForServicesStarted();

    fixture.signalGroup(ProcessSignal.sigint);

    expect(await fixture.exitCode, 130);
    fixture.expectWorkerStopped();
    fixture.expectComposeDownOnce();
  });

  test('SIGTERM to the CLI stops Orchard and Compose', () async {
    await fixture.start();
    await fixture.waitForServicesStarted();

    fixture.signalCli(ProcessSignal.sigterm);

    expect(await fixture.exitCode, 143);
    fixture.expectWorkerStopped();
    fixture.expectComposeDownOnce();
  });

  test('repeated signals do not run Compose down again', () async {
    await fixture.start(blockDown: true);
    await fixture.waitForServicesStarted();

    fixture.signalGroup(ProcessSignal.sigint);
    await fixture.waitFor(fixture.downStarted, 'Compose down to start');
    fixture.signalCli(ProcessSignal.sigint);
    fixture.signalCli(ProcessSignal.sigterm);
    fixture.downRelease.createSync();

    expect(await fixture.exitCode, 130);
    fixture.expectWorkerStopped();
    fixture.expectComposeDownOnce();
  });

  test('waits for an interrupted Compose up before running down', () async {
    await fixture.start(blockAuthUp: true);
    await fixture.waitFor(fixture.authStarted, 'auth emulator up to start');

    fixture.signalCli(ProcessSignal.sigterm);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(fixture.downStarted.existsSync(), isFalse);
    fixture.authRelease.createSync();

    expect(await fixture.exitCode, 143);
    expect(fixture.logLines, isNot(contains('orchard worker started')));
    fixture.expectComposeDownOnce();
  });

  test('reports a failed Compose down after stopping Orchard', () async {
    await fixture.start(failDown: true);
    await fixture.waitForServicesStarted();

    fixture.signalCli(ProcessSignal.sigterm);

    expect(await fixture.exitCode, 1);
    fixture.expectWorkerStopped();
    fixture.expectComposeDownOnce();
  });
}

class _DevStartFixture {
  final Directory directory;
  final Directory packageRoot;
  final File log;
  final File cliPidFile;
  final File authStarted;
  final File authRelease;
  final File workerStarted;
  final File downStarted;
  final File downRelease;
  Process? _launcher;
  int? _cliPid;
  var _exited = false;
  final _stdout = StringBuffer();
  final _stderr = StringBuffer();

  _DevStartFixture._(this.directory, this.packageRoot)
    : log = File(p.join(directory.path, 'commands.log')),
      cliPidFile = File(p.join(directory.path, 'cli.pid')),
      authStarted = File(p.join(directory.path, 'auth-started')),
      authRelease = File(p.join(directory.path, 'auth-release')),
      workerStarted = File(p.join(directory.path, 'worker-started')),
      downStarted = File(p.join(directory.path, 'down-started')),
      downRelease = File(p.join(directory.path, 'down-release'));

  static Future<_DevStartFixture> create() async {
    final packageUri = await Isolate.resolvePackageUri(
      Uri.parse('package:openci_cli/openci_cli.dart'),
    );
    if (packageUri == null) {
      throw StateError('Cannot find the openci_cli package');
    }
    final directory = await Directory.systemTemp.createTemp(
      'openci_dev_start_process_',
    );
    final fixture = _DevStartFixture._(
      directory,
      File.fromUri(packageUri).parent.parent,
    );
    final bin = await Directory(p.join(directory.path, 'bin')).create();
    await fixture._writeExecutable(bin, 'tart', r'''#!/bin/bash
printf 'tart %s\n' "$*" >> "$OPENCI_TEST_LOG"
printf 'base-macos\n'
''');
    await fixture._writeExecutable(bin, 'docker', r'''#!/bin/bash
printf 'docker %s\n' "$*" >> "$OPENCI_TEST_LOG"
if [[ "$1" == exec ]]; then
  printf 'test-token\n'
  exit 0
fi
if [[ "$*" == *firebase-auth ]]; then
  touch "$OPENCI_TEST_AUTH_STARTED"
  if [[ "$OPENCI_TEST_BLOCK_AUTH_UP" == 1 ]]; then
    while [[ ! -f "$OPENCI_TEST_AUTH_RELEASE" ]]; do sleep 0.05; done
  fi
fi
if [[ "$*" == *'down --remove-orphans' ]]; then
  touch "$OPENCI_TEST_DOWN_STARTED"
  if [[ "$OPENCI_TEST_BLOCK_DOWN" == 1 ]]; then
    trap ':' INT
    while [[ ! -f "$OPENCI_TEST_DOWN_RELEASE" ]]; do sleep 0.05; done
  fi
  if [[ "$OPENCI_TEST_FAIL_DOWN" == 1 ]]; then exit 42; fi
fi
''');
    await fixture._writeExecutable(bin, 'orchard', r'''#!/bin/bash
if [[ "$1" == get ]]; then
  printf 'test-token\n'
  exit 0
fi
if [[ "$1" == context ]]; then exit 0; fi
if [[ "$1" == worker ]]; then
  printf 'orchard worker started\n' >> "$OPENCI_TEST_LOG"
  trap 'printf "orchard worker stopped\n" >> "$OPENCI_TEST_LOG"; exit 0' INT TERM
  touch "$OPENCI_TEST_WORKER_STARTED"
  while :; do sleep 0.05; done
fi
exit 2
''');
    return fixture;
  }

  Future<void> _writeExecutable(
    Directory bin,
    String name,
    String script,
  ) async {
    final path = p.join(bin.path, name);
    await File(path).writeAsString(script);
    final chmod = await Process.run('chmod', ['+x', path]);
    if (chmod.exitCode != 0) {
      throw StateError('chmod failed for $path: ${chmod.stderr}');
    }
  }

  Future<void> start({
    bool blockAuthUp = false,
    bool blockDown = false,
    bool failDown = false,
  }) async {
    // Bash job control gives the CLI its own process group. SIGINT then
    // reproduces a terminal interrupt without signaling the test runner.
    const launcher = r'''
set -m
"$@" &
cli=$!
printf '%s\n' "$cli" > "$OPENCI_TEST_CLI_PID_FILE"
wait "$cli"
exit $?
''';
    _launcher = await Process.start(
      '/bin/bash',
      [
        '-c',
        launcher,
        'openci-process-test',
        Platform.resolvedExecutable,
        'bin/openci_cli.dart',
        'dev',
        'start',
      ],
      workingDirectory: packageRoot.path,
      environment: {
        ...Platform.environment,
        'HOME': directory.path,
        'XDG_CONFIG_HOME': p.join(directory.path, 'config'),
        'PATH':
            '${p.join(directory.path, 'bin')}:${Platform.environment['PATH'] ?? '/usr/bin:/bin'}',
        'OPENCI_TEST_LOG': log.path,
        'OPENCI_TEST_CLI_PID_FILE': cliPidFile.path,
        'OPENCI_TEST_AUTH_STARTED': authStarted.path,
        'OPENCI_TEST_AUTH_RELEASE': authRelease.path,
        'OPENCI_TEST_WORKER_STARTED': workerStarted.path,
        'OPENCI_TEST_DOWN_STARTED': downStarted.path,
        'OPENCI_TEST_DOWN_RELEASE': downRelease.path,
        'OPENCI_TEST_BLOCK_AUTH_UP': blockAuthUp ? '1' : '0',
        'OPENCI_TEST_BLOCK_DOWN': blockDown ? '1' : '0',
        'OPENCI_TEST_FAIL_DOWN': failDown ? '1' : '0',
      },
    );
    _launcher!.stdout.transform(utf8.decoder).listen(_stdout.write);
    _launcher!.stderr.transform(utf8.decoder).listen(_stderr.write);
    await waitFor(cliPidFile, 'CLI process to start');
    _cliPid = int.parse(await cliPidFile.readAsString());

    final group = await Process.run('ps', ['-o', 'pgid=', '-p', '$_cliPid']);
    expect(group.exitCode, 0, reason: '${group.stderr}');
    expect(
      int.parse((group.stdout as String).trim()),
      _cliPid,
      reason: 'The CLI must own a separate process group',
    );
  }

  void signalGroup(ProcessSignal signal) {
    expect(Process.killPid(-_cliPid!, signal), isTrue);
  }

  void signalCli(ProcessSignal signal) {
    expect(Process.killPid(_cliPid!, signal), isTrue);
  }

  Future<int> get exitCode async {
    final code = await _launcher!.exitCode.timeout(_timeout);
    _exited = true;
    return code;
  }

  List<String> get logLines => log.existsSync()
      ? log.readAsLinesSync().where((line) => line.isNotEmpty).toList()
      : [];

  void expectWorkerStopped() {
    expect(logLines, contains('orchard worker started'));
    expect(
      logLines.where((line) => line == 'orchard worker stopped'),
      hasLength(1),
    );
  }

  void expectComposeDownOnce() {
    final downs = logLines.where(
      (line) => line.startsWith('docker compose ') && line.contains(' down '),
    );
    expect(downs, [
      'docker compose -f docker-compose.yml -f docker-compose.local.yml '
          '-f docker-compose.local-api.yml down --remove-orphans',
    ]);
  }

  Future<void> waitForServicesStarted() async {
    await waitFor(workerStarted, 'Orchard worker to start');
    final deadline = DateTime.now().add(_timeout);
    while (!_stdout.toString().contains('Docker containers started.') &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(
      _stdout.toString(),
      contains('Docker containers started.'),
      reason:
          'Timed out waiting for Compose services to finish starting.\n'
          'Commands: $logLines\nstderr: $_stderr',
    );
  }

  Future<void> waitFor(File marker, String description) async {
    final deadline = DateTime.now().add(_timeout);
    while (!marker.existsSync() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(
      marker.existsSync(),
      isTrue,
      reason:
          'Timed out waiting for $description.\n'
          'Commands: $logLines\nstdout: $_stdout\nstderr: $_stderr',
    );
  }

  Future<void> dispose() async {
    if (!_exited && _cliPid != null) {
      final group = await Process.run('ps', ['-o', 'pgid=', '-p', '$_cliPid']);
      if (group.exitCode == 0 &&
          (group.stdout as String).trim() == '$_cliPid') {
        Process.killPid(-_cliPid!, ProcessSignal.sigkill);
      }
    }
    if (_launcher != null) {
      await _launcher!.exitCode.timeout(_timeout);
    }
    await directory.delete(recursive: true);
  }
}
