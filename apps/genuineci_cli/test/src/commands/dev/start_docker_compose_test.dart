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

    test('starts the core services from the project root', () async {
      late String executable;
      late List<String> arguments;
      late String capturedWorkingDirectory;
      late Map<String, String> capturedEnvironment;

      final result = await startDockerCompose(
        logger,
        projectRoot,
        environment: const {
          'PATH': '/usr/local/bin',
          'BASE_VM_NAME': 'custom-base',
          'ORCHARD_API_URL': 'https://ignored.example.com',
        },
        processRunner:
            (
              processExecutable,
              processArguments, {
              required workingDirectory,
              required environment,
            }) async {
              executable = processExecutable;
              arguments = processArguments;
              capturedWorkingDirectory = workingDirectory;
              capturedEnvironment = environment;
              return 0;
            },
      );

      expect(result, isTrue);
      expect(executable, equals('docker'));
      expect(
        arguments,
        equals([
          'compose',
          'up',
          '-d',
          '--build',
          'db',
          'orchard-controller',
          'server',
          'build-job-dispatcher',
        ]),
      );
      expect(capturedWorkingDirectory, equals(projectRoot.path));
      expect(capturedEnvironment, {
        'PATH': '/usr/local/bin',
        'BASE_VM_NAME': 'custom-base',
        'ORCHARD_API_URL': 'https://orchard-controller:6120',
        'INTERNAL_API_KEY': 'genuineci-local-dev-key',
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
