import 'dart:async';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/src/commands/dev/start_orchard_worker.dart';
import 'package:openci_cli/src/i18n/i18n.dart';
import 'package:test/test.dart';

class _RecordingLogger implements Logger {
  final stdoutMessages = <String>[];
  final stderrMessages = <String>[];

  @override
  void stdout(String message) => stdoutMessages.add(message);

  @override
  void stderr(String message) => stderrMessages.add(message);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WorkerProcess implements Process {
  final exited = Completer<int>();
  final signals = <ProcessSignal>[];

  @override
  Future<int> get exitCode => exited.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    signals.add(signal);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingLogger logger;
  late _WorkerProcess worker;
  const token = 'test-bootstrap-token';

  setUp(() {
    logger = _RecordingLogger();
    worker = _WorkerProcess();
  });

  test(
    'starts the local worker with terminal output before waiting for exit',
    () async {
      final calls = <List<String>>[];
      final started = Completer<void>();
      var completed = false;

      final result = await startOrchardWorker(
        logger,
        processRunner: (executable, arguments) async {
          calls.add([executable, ...arguments]);
          return ProcessResult(1, 0, '$token\n', '');
        },
        processStarter: (executable, arguments, {required mode}) async {
          calls.add([executable, ...arguments]);
          expect(mode, ProcessStartMode.inheritStdio);
          started.complete();
          return worker;
        },
      );
      final exitCode = result!.exitCode.then((code) {
        completed = true;
        return code;
      });
      await started.future;
      expect(result.isRunning, isTrue);
      expect(completed, isFalse);
      worker.exited.complete(0);

      expect(await exitCode, 0);
      expect(result.isRunning, isFalse);
      expect(calls, [
        ['orchard', 'get', 'bootstrap-token', 'bootstrap-admin'],
        [
          'orchard',
          'worker',
          'run',
          'https://127.0.0.1:6120',
          '--bootstrap-token',
          token,
          '--no-pki',
        ],
      ]);
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepOrchardWorker}']);
      expect(logger.stderrMessages, isEmpty);
    },
  );

  for (final code in [17, -9]) {
    test('reports worker exit $code as a shell exit code', () async {
      worker.exited.complete(code);
      final result = await startOrchardWorker(
        logger,
        processRunner: (_, _) async => ProcessResult(1, 0, token, ''),
        processStarter: (_, _, {required mode}) async => worker,
      );

      expect(await result!.exitCode, code == 17 ? 17 : 137);
      expect(result.isRunning, isFalse);
      expect(logger.stderrMessages, [t.dev.start.stepOrchardWorkerFailed]);
    });
  }

  for (final tokenResult in [
    ProcessResult(1, 1, token, 'private error'),
    ProcessResult(1, 0, ' \n', ''),
  ]) {
    test(
      'rejects a token result with exit code ${tokenResult.exitCode}',
      () async {
        final result = await startOrchardWorker(
          logger,
          processRunner: (_, _) async => tokenResult,
          processStarter: (_, _, {required mode}) async =>
              fail('Worker must not start'),
        );

        expect(result, isNull);
        expect(logger.stdoutMessages, isEmpty);
        expect(logger.stderrMessages, [t.dev.start.stepOrchardWorkerFailed]);
      },
    );
  }

  for (final failTokenCommand in [true, false]) {
    test(
      'reports a process failure (token command: $failTokenCommand)',
      () async {
        final result = await startOrchardWorker(
          logger,
          processRunner: (executable, arguments) async {
            if (failTokenCommand) {
              throw ProcessException(executable, arguments, 'not found');
            }
            return ProcessResult(1, 0, token, '');
          },
          processStarter: (executable, arguments, {required mode}) async {
            throw ProcessException(executable, arguments, 'not found');
          },
        );

        expect(result, isNull);
        expect(logger.stderrMessages, [
          '${t.dev.start.stepOrchardWorkerFailed}\nnot found',
        ]);
        expect(logger.stderrMessages.join(), isNot(contains(token)));
      },
    );
  }

  for (final signal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
    test('stops the worker on $signal and waits for shutdown', () async {
      final listening = Completer<void>();
      final interrupts = StreamController<ProcessSignal>(sync: true);
      final terminations = StreamController<ProcessSignal>(
        sync: true,
        onListen: listening.complete,
      );
      addTearDown(interrupts.close);
      addTearDown(terminations.close);
      var completed = false;

      final result = await startOrchardWorker(
        logger,
        processRunner: (_, _) async => ProcessResult(1, 0, token, ''),
        processStarter: (_, _, {required mode}) async => worker,
        interruptSignals: interrupts.stream,
        terminateSignals: terminations.stream,
      );
      final exitCode = result!.exitCode.then((code) {
        completed = true;
        return code;
      });
      await listening.future;
      (signal == ProcessSignal.sigint ? interrupts : terminations).add(signal);

      expect(worker.signals, [ProcessSignal.sigint]);
      expect(result.isRunning, isFalse);
      expect(completed, isFalse);
      worker.exited.complete(1);
      expect(await exitCode, 128 + signal.signalNumber);
      expect(result.isRunning, isFalse);
      await result.stop();
      expect(worker.signals, [ProcessSignal.sigint]);
      expect(logger.stderrMessages, isEmpty);
      expect(interrupts.hasListener, isFalse);
      expect(terminations.hasListener, isFalse);
    });
  }

  test('stop waits for cleanup and only sends one signal', () async {
    final interrupts = StreamController<ProcessSignal>();
    final terminations = StreamController<ProcessSignal>();
    addTearDown(interrupts.close);
    addTearDown(terminations.close);
    final result = await startOrchardWorker(
      logger,
      processRunner: (_, _) async => ProcessResult(1, 0, token, ''),
      processStarter: (_, _, {required mode}) async => worker,
      interruptSignals: interrupts.stream,
      terminateSignals: terminations.stream,
    );
    var stopped = false;
    final stopping = result!.stop().then((_) => stopped = true);
    final alsoStopping = result.stop();

    expect(result.isRunning, isFalse);
    expect(stopped, isFalse);
    expect(worker.signals, [ProcessSignal.sigint]);
    worker.exited.complete(1);
    await stopping;
    await alsoStopping;
    expect(stopped, isTrue);
    expect(interrupts.hasListener, isFalse);
    expect(terminations.hasListener, isFalse);
    expect(logger.stderrMessages, isEmpty);
  });
}
