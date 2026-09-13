import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/src/commands/dev/start_docker_compose.dart';
import 'package:genuineci_cli/src/i18n/i18n.dart';
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

void main() {
  group('startDockerCompose', () {
    late _RecordingLogger logger;
    late Directory projectRoot;

    setUp(() {
      logger = _RecordingLogger();
      projectRoot = Directory('/path/to/openci');
    });

    for (final (step, arguments, message) in [
      (
        DockerComposeStep.startOrchardController,
        [
          'compose',
          'up',
          '-d',
          '--no-recreate',
          '--remove-orphans',
          'orchard-controller',
        ],
        t.dev.start.stepOrchardController,
      ),
      (
        DockerComposeStep.stopBuildJobWorker,
        ['compose', 'stop', 'build-job-worker'],
        t.dev.start.stepBuildJobWorkerWaiting,
      ),
    ]) {
      test('$step passes the expected Compose arguments', () async {
        final calls = <List<String>>[];
        final result = await startDockerCompose(
          logger,
          projectRoot,
          step: step,
          environment: const {'PATH': '/usr/local/bin'},
          processRunner:
              (
                executable,
                args, {
                required workingDirectory,
                required environment,
              }) async {
                expect(executable, 'docker');
                expect(workingDirectory, projectRoot.path);
                expect(environment, {
                  'PATH': '/usr/local/bin',
                  'ENABLE_INTERNAL_API': 'true',
                });
                calls.add(args);
                return 0;
              },
        );

        expect(result, isTrue);
        expect(calls, [arguments]);
        expect(logger.stdoutMessages, ['\n$message']);
        expect(logger.stderrMessages, isEmpty);
      });
    }

    test('starts worker services from the project root', () async {
      late String executable;
      final calls = <List<String>>[];
      late String capturedWorkingDirectory;
      late Map<String, String> capturedEnvironment;

      final result = await startDockerCompose(
        logger,
        projectRoot,
        environment: const {
          'PATH': '/usr/local/bin',
          'BASE_VM_NAME': 'custom-base',
          'INTERNAL_API_KEY': 'custom-api-key',
          'ORCHARD_API_URL': 'https://custom-orchard.example.com',
        },
        processRunner:
            (
              processExecutable,
              processArguments, {
              required workingDirectory,
              required environment,
            }) async {
              executable = processExecutable;
              calls.add(processArguments);
              capturedWorkingDirectory = workingDirectory;
              capturedEnvironment = environment;
              return 0;
            },
      );

      expect(result, isTrue);
      expect(executable, equals('docker'));
      expect(calls, [
        [
          'compose',
          'up',
          '-d',
          '--build',
          '--remove-orphans',
          'server',
          'build-job-planner',
          'build-job-worker',
          'loki',
        ],
      ]);
      expect(capturedWorkingDirectory, equals(projectRoot.path));
      expect(capturedEnvironment, {
        'PATH': '/usr/local/bin',
        'BASE_VM_NAME': 'custom-base',
        'INTERNAL_API_KEY': 'custom-api-key',
        'ORCHARD_API_URL': 'https://custom-orchard.example.com',
        'ENABLE_INTERNAL_API': 'true',
      });
      expect(logger.stderrMessages, isEmpty);
      expect(
        logger.stdoutMessages,
        equals([
          '\n${t.dev.start.stepDockerCompose}',
          t.dev.start.stepDockerComposeStarted,
        ]),
      );
    });

    test('enables the API without mutating the input', () async {
      late Map<String, String> capturedEnvironment;
      final suppliedEnvironment = {
        'PATH': '/usr/local/bin',
        'ENABLE_INTERNAL_API': 'false',
      };

      final result = await startDockerCompose(
        logger,
        projectRoot,
        environment: suppliedEnvironment,
        processRunner:
            (_, _, {required workingDirectory, required environment}) async {
              capturedEnvironment = environment;
              return 0;
            },
      );

      expect(result, isTrue);
      expect(capturedEnvironment, {
        'PATH': '/usr/local/bin',
        'ENABLE_INTERNAL_API': 'true',
      });
      expect(suppliedEnvironment, {
        'PATH': '/usr/local/bin',
        'ENABLE_INTERNAL_API': 'false',
      });
    });

    test(
      'inherits the process environment when no override is given',
      () async {
        late Map<String, String> capturedEnvironment;

        final result = await startDockerCompose(
          logger,
          projectRoot,
          processRunner:
              (_, _, {required workingDirectory, required environment}) async {
                capturedEnvironment = environment;
                return 0;
              },
        );

        expect(result, isTrue);
        expect(
          capturedEnvironment.keys,
          unorderedEquals({
            ...Platform.environment.keys,
            'ENABLE_INTERNAL_API',
          }),
        );
        expect(capturedEnvironment['ENABLE_INTERNAL_API'], 'true');
        expect(
          capturedEnvironment.entries
              .where((entry) => entry.key != 'ENABLE_INTERNAL_API')
              .every((entry) => entry.value == Platform.environment[entry.key]),
          isTrue,
        );
      },
    );

    test('returns false when Docker Compose exits with an error', () async {
      const dockerComposeFailureExitCode = 17;

      final result = await startDockerCompose(
        logger,
        projectRoot,
        environment: const {},
        processRunner:
            (_, _, {required workingDirectory, required environment}) async =>
                dockerComposeFailureExitCode,
      );

      expect(result, isFalse);
      expect(logger.stderrMessages, [t.dev.start.stepDockerComposeFailed]);
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepDockerCompose}']);
    });

    test('returns false when Docker cannot be started', () async {
      final result = await startDockerCompose(
        logger,
        projectRoot,
        environment: const {},
        processRunner:
            (
              executable,
              arguments, {
              required workingDirectory,
              required environment,
            }) async {
              throw ProcessException(executable, arguments, 'not found');
            },
      );

      expect(result, isFalse);
      expect(logger.stderrMessages, hasLength(1));
      expect(
        logger.stderrMessages.single,
        contains(t.dev.start.stepDockerComposeFailed),
      );
      expect(logger.stderrMessages.single, contains('not found'));
    });
  });
}
