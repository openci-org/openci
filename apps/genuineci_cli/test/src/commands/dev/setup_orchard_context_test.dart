import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/src/commands/dev/setup_orchard_context.dart';
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
  group('setupOrchardContext', () {
    late _RecordingLogger logger;

    setUp(() {
      logger = _RecordingLogger();
    });

    test('registers and selects the default context', () async {
      const bootstrapToken = 'test-bootstrap-token';
      final calls = <({String executable, List<String> arguments})>[];

      final result = await setupOrchardContext(
        logger,
        processRunner: (executable, arguments) async {
          calls.add((
            executable: executable,
            arguments: List<String>.of(arguments),
          ));
          if (executable == 'docker') {
            return ProcessResult(1, 0, '$bootstrapToken\n', '');
          }
          return ProcessResult(2, 0, '', '');
        },
      );

      expect(result, isTrue);
      expect(calls, hasLength(3));
      expect(calls[0].executable, equals('docker'));
      expect(calls[0].arguments, [
        'exec',
        'openci-orchard-controller',
        'orchard',
        'get',
        'bootstrap-token',
        'bootstrap-admin',
      ]);
      expect(calls[1].executable, equals('orchard'));
      expect(calls[1].arguments, [
        'context',
        'create',
        'https://127.0.0.1:6120',
        '--bootstrap-token',
        bootstrapToken,
        '--no-pki',
        '--force',
      ]);
      expect(calls[2].executable, equals('orchard'));
      expect(calls[2].arguments, ['context', 'default', 'default']);
      expect(logger.stderrMessages, isEmpty);
      expect(logger.stdoutMessages, [
        '\n${t.dev.start.stepOrchardWaiting}',
        '\n${t.dev.start.stepOrchardContext}',
        t.dev.start.stepOrchardContextRegistered,
      ]);
    });

    test('retries until the bootstrap token is available', () async {
      var tokenAttempts = 0;
      final delays = <Duration>[];

      final result = await setupOrchardContext(
        logger,
        maxAttempts: 3,
        retryInterval: const Duration(milliseconds: 250),
        delay: (duration) async => delays.add(duration),
        processRunner: (executable, arguments) async {
          if (executable == 'docker') {
            tokenAttempts++;
            if (tokenAttempts == 1) {
              return ProcessResult(1, 1, '', 'not ready');
            }
            if (tokenAttempts == 2) {
              return ProcessResult(2, 0, '', '');
            }
            return ProcessResult(3, 0, 'test-bootstrap-token\n', '');
          }
          return ProcessResult(4, 0, '', '');
        },
      );

      expect(result, isTrue);
      expect(tokenAttempts, equals(3));
      expect(delays, [
        const Duration(milliseconds: 250),
        const Duration(milliseconds: 250),
      ]);
    });

    test('returns false when the controller never becomes ready', () async {
      var tokenAttempts = 0;
      var delayCount = 0;

      final result = await setupOrchardContext(
        logger,
        maxAttempts: 3,
        retryInterval: Duration.zero,
        delay: (_) async => delayCount++,
        processRunner: (_, _) async {
          tokenAttempts++;
          return ProcessResult(tokenAttempts, 1, '', 'not ready');
        },
      );

      expect(result, isFalse);
      expect(tokenAttempts, equals(3));
      expect(delayCount, equals(2));
      expect(logger.stderrMessages, [t.dev.start.stepOrchardNotReady]);
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepOrchardWaiting}']);
    });

    test('returns false when context creation fails', () async {
      var processCall = 0;

      final result = await setupOrchardContext(
        logger,
        processRunner: (_, _) async {
          processCall++;
          if (processCall == 1) {
            return ProcessResult(1, 0, 'test-bootstrap-token\n', '');
          }
          return ProcessResult(2, 1, '', 'context creation failed');
        },
      );

      expect(result, isFalse);
      expect(processCall, equals(2));
      expect(logger.stderrMessages, [t.dev.start.stepOrchardContextFailed]);
    });

    test('returns false when the default context cannot be selected', () async {
      var processCall = 0;

      final result = await setupOrchardContext(
        logger,
        processRunner: (_, _) async {
          processCall++;
          if (processCall == 1) {
            return ProcessResult(1, 0, 'test-bootstrap-token\n', '');
          }
          if (processCall == 2) {
            return ProcessResult(2, 0, '', '');
          }
          return ProcessResult(3, 1, '', 'context selection failed');
        },
      );

      expect(result, isFalse);
      expect(processCall, equals(3));
      expect(logger.stderrMessages, [t.dev.start.stepOrchardContextFailed]);
    });

    test('returns false when Docker cannot be started', () async {
      final result = await setupOrchardContext(
        logger,
        processRunner: (executable, arguments) async {
          throw ProcessException(executable, arguments, 'not found');
        },
      );

      expect(result, isFalse);
      expect(logger.stderrMessages, hasLength(1));
      expect(
        logger.stderrMessages.single,
        contains(t.dev.start.stepOrchardNotReady),
      );
      expect(logger.stderrMessages.single, contains('not found'));
    });
  });
}
