import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/src/commands/dev/dev_start_command.dart';
import 'package:openci_cli/src/commands/dev/start_docker_compose.dart';
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

class _OrchardWorker implements OrchardWorker {
  @override
  bool isRunning = true;
  bool stopped = false;
  @override
  Future<int> exitCode = Future.value(0);

  @override
  Future<void> stop() async {
    stopped = true;
    isRunning = false;
  }
}

void main() {
  late Directory originalDirectory;
  late Directory tempDirectory;

  setUp(() async {
    originalDirectory = Directory.current;
    tempDirectory = await Directory.systemTemp.createTemp(
      'dev_start_command_test_',
    );
    Directory.current = tempDirectory;
  });

  tearDown(() async {
    Directory.current = originalDirectory;
    await tempDirectory.delete(recursive: true);
  });

  Future<int?> runStart({
    required bool shouldSeed,
    required bool seedSucceeds,
    required void Function() onSeed,
    OrchardWorkerStarter? orchardWorkerStarter,
  }) {
    final runner = CommandRunner<int>('openci', 'CLI tool')
      ..addCommand(
        DevStartCommand(
          logger: _RecordingLogger(),
          projectRootFinder: () => tempDirectory,
          tartBaseImageChecker: (_) async => true,
          dockerComposeStarter:
              (_, _, {step = DockerComposeStep.startServices}) async => true,
          orchardContextSetup: (_) async => true,
          localDataSeeder: (_, {required projectRoot}) async {
            expect(projectRoot, same(tempDirectory));
            onSeed();
            return seedSucceeds;
          },
          orchardWorkerStarter:
              orchardWorkerStarter ?? (_) async => _OrchardWorker(),
        ),
      );

    return runner.run(['start', if (shouldSeed) '--seed']);
  }

  test('reports projectRootNotFound before checking Tart', () async {
    final logger = _RecordingLogger();

    final result = await DevStartCommand(logger: logger).run();

    expect(result, equals(1));
    expect(logger.stdoutMessages, equals([t.dev.start.starting]));
    expect(logger.stderrMessages, equals([t.dev.start.projectRootNotFound]));
  });

  test('seed flag is opt-in', () {
    final command = DevStartCommand(logger: _RecordingLogger());

    expect(command.argParser.parse([]).flag('seed'), isFalse);
    expect(command.argParser.parse(['--seed']).flag('seed'), isTrue);
    expect(command.argParser.usage, contains(t.dev.start.flags.seed));
  });

  test('does not seed local data when --seed is omitted', () async {
    var seedCallCount = 0;

    final result = await runStart(
      shouldSeed: false,
      seedSucceeds: true,
      onSeed: () => seedCallCount++,
    );

    expect(result, equals(0));
    expect(seedCallCount, equals(0));
  });

  test('seeds local data when --seed is specified', () async {
    var seedCallCount = 0;

    final result = await runStart(
      shouldSeed: true,
      seedSucceeds: true,
      onSeed: () => seedCallCount++,
    );

    expect(result, equals(0));
    expect(seedCallCount, equals(1));
  });

  test('returns 1 when seeding local data fails', () async {
    var seedCallCount = 0;
    final worker = _OrchardWorker();

    final result = await runStart(
      shouldSeed: true,
      seedSucceeds: false,
      onSeed: () => seedCallCount++,
      orchardWorkerStarter: (_) async => worker,
    );

    expect(result, equals(1));
    expect(seedCallCount, equals(1));
    expect(worker.stopped, isTrue);
  });

  for (final shouldSeed in [false, true]) {
    test('starts Orchard before draining (seed=$shouldSeed)', () async {
      final calls = <String>[];
      bool recordStep(String step) {
        calls.add(step);
        return true;
      }

      final logger = _RecordingLogger();
      final worker = _OrchardWorker()..exitCode = Future.value(17);
      final runner = CommandRunner<int>('openci', 'CLI tool')
        ..addCommand(
          DevStartCommand(
            logger: logger,
            projectRootFinder: () => tempDirectory,
            tartBaseImageChecker: (_) async => recordStep('tart'),
            dockerComposeStarter:
                (
                  composeLogger,
                  root, {
                  step = DockerComposeStep.startServices,
                }) async {
                  expect(composeLogger, same(logger));
                  expect(root, same(tempDirectory));
                  return recordStep(step.name);
                },
            orchardContextSetup: (_) async => recordStep('context'),
            localDataSeeder: (_, {required projectRoot}) async =>
                recordStep('seed'),
            orchardWorkerStarter: (workerLogger) async {
              expect(workerLogger, same(logger));
              calls.add('worker');
              return worker;
            },
          ),
        );

      expect(await runner.run(['start', if (shouldSeed) '--seed']), 17);
      expect(calls, [
        'tart',
        'startAuthEmulator',
        'startOrchardController',
        'context',
        'worker',
        'stopBuildJobWorker',
        'startServices',
        if (shouldSeed) 'seed',
      ]);
      expect(worker.stopped, isTrue);
    });
  }

  for (final failingStep in [
    'tart',
    'startAuthEmulator',
    'startOrchardController',
    'context',
  ]) {
    test('does not start the worker when $failingStep fails', () async {
      final composeSteps = <DockerComposeStep>[];
      final result = await DevStartCommand(
        logger: _RecordingLogger(),
        projectRootFinder: () => tempDirectory,
        tartBaseImageChecker: (_) async => failingStep != 'tart',
        dockerComposeStarter:
            (_, _, {step = DockerComposeStep.startServices}) async {
              composeSteps.add(step);
              return step.name != failingStep;
            },
        orchardContextSetup: (_) async => failingStep != 'context',
        orchardWorkerStarter: (_) async => fail('Worker must not start'),
      ).run();

      expect(result, 1);
      expect(composeSteps, [
        if (failingStep != 'tart') DockerComposeStep.startAuthEmulator,
        if (failingStep == 'context' || failingStep == 'startOrchardController')
          DockerComposeStep.startOrchardController,
      ]);
    });
  }

  test(
    'does not stop app containers when the Mac worker cannot start',
    () async {
      final steps = <DockerComposeStep>[];
      final result = await DevStartCommand(
        logger: _RecordingLogger(),
        projectRootFinder: () => tempDirectory,
        tartBaseImageChecker: (_) async => true,
        dockerComposeStarter:
            (_, _, {step = DockerComposeStep.startServices}) async {
              steps.add(step);
              return true;
            },
        orchardContextSetup: (_) async => true,
        orchardWorkerStarter: (_) async => null,
      ).run();

      expect(result, 1);
      expect(steps, [
        DockerComposeStep.startAuthEmulator,
        DockerComposeStep.startOrchardController,
      ]);
    },
  );

  test(
    'waits for the old job before rebuilding and keeps Orchard alive',
    () async {
      final worker = _OrchardWorker();
      final workerExit = Completer<int>();
      worker.exitCode = workerExit.future;
      final draining = Completer<void>();
      final drained = Completer<bool>();
      final rebuilt = Completer<void>();
      var completed = false;
      final result =
          DevStartCommand(
            logger: _RecordingLogger(),
            projectRootFinder: () => tempDirectory,
            tartBaseImageChecker: (_) async => true,
            dockerComposeStarter:
                (_, _, {step = DockerComposeStep.startServices}) async {
                  if (step == DockerComposeStep.stopBuildJobWorker) {
                    draining.complete();
                    return drained.future;
                  }
                  if (step == DockerComposeStep.startServices) {
                    expect(drained.isCompleted, isTrue);
                    expect(worker.isRunning, isTrue);
                    rebuilt.complete();
                  }
                  return true;
                },
            orchardContextSetup: (_) async => true,
            orchardWorkerStarter: (_) async => worker,
          ).run().then((code) {
            completed = true;
            return code;
          });

      await draining.future;
      expect(rebuilt.isCompleted, isFalse);
      expect(worker.stopped, isFalse);
      drained.complete(true);
      await rebuilt.future;
      expect(completed, isFalse);
      expect(worker.stopped, isFalse);
      workerExit.complete(0);
      expect(await result, 0);
      expect(worker.stopped, isTrue);
    },
  );

  for (final failedStep in [
    DockerComposeStep.stopBuildJobWorker,
    DockerComposeStep.startServices,
  ]) {
    for (final throwsError in [false, true]) {
      test(
        'stops Orchard when $failedStep fails (throws: $throwsError)',
        () async {
          final worker = _OrchardWorker();
          final steps = <DockerComposeStep>[];
          final runner = CommandRunner<int>('openci', 'CLI tool')
            ..addCommand(
              DevStartCommand(
                logger: _RecordingLogger(),
                projectRootFinder: () => tempDirectory,
                tartBaseImageChecker: (_) async => true,
                dockerComposeStarter:
                    (_, _, {step = DockerComposeStep.startServices}) async {
                      steps.add(step);
                      if (step == failedStep && throwsError) {
                        throw StateError('compose failed');
                      }
                      return step != failedStep;
                    },
                orchardContextSetup: (_) async => true,
                orchardWorkerStarter: (_) async => worker,
                localDataSeeder: (_, {required projectRoot}) async =>
                    fail('Must not seed after a failure'),
              ),
            );

          final result = runner.run(['start', '--seed']);
          if (throwsError) {
            await expectLater(result, throwsStateError);
          } else {
            expect(await result, 1);
          }
          expect(steps, [
            DockerComposeStep.startAuthEmulator,
            DockerComposeStep.startOrchardController,
            DockerComposeStep.stopBuildJobWorker,
            if (failedStep == DockerComposeStep.startServices)
              DockerComposeStep.startServices,
          ]);
          expect(worker.stopped, isTrue);
        },
      );
    }
  }

  for (final code in [0, 17, 130]) {
    test(
      'does not rebuild if Orchard exits while draining with code $code',
      () async {
        final worker = _OrchardWorker()..exitCode = Future.value(code);
        final steps = <DockerComposeStep>[];
        final result = await DevStartCommand(
          logger: _RecordingLogger(),
          projectRootFinder: () => tempDirectory,
          tartBaseImageChecker: (_) async => true,
          dockerComposeStarter:
              (_, _, {step = DockerComposeStep.startServices}) async {
                steps.add(step);
                if (step == DockerComposeStep.stopBuildJobWorker) {
                  worker.isRunning = false;
                }
                return true;
              },
          orchardContextSetup: (_) async => true,
          orchardWorkerStarter: (_) async => worker,
        ).run();

        expect(result, code == 0 ? 1 : code);
        expect(steps, [
          DockerComposeStep.startAuthEmulator,
          DockerComposeStep.startOrchardController,
          DockerComposeStep.stopBuildJobWorker,
        ]);
        expect(worker.stopped, isTrue);
      },
    );
  }
}
