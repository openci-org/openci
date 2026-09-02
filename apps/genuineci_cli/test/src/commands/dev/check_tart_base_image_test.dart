import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/src/commands/dev/check_tart_base_image.dart';
import 'package:test/test.dart';

void main() {
  group('hasExactVmName', () {
    test('returns true when exact VM name exists in single line output', () {
      expect(hasExactVmName('base-macos', 'base-macos'), isTrue);
    });

    test('returns true when exact VM name is listed among multiple rows', () {
      const output = 'other-vm\nbase-macos\ndevelopment-vm\n';
      expect(hasExactVmName(output, 'base-macos'), isTrue);
    });

    test(
      'returns false when VM name is only a substring (e.g. base-macos-old)',
      () {
        const output = 'base-macos-old\nmy-base-macos\n';
        expect(hasExactVmName(output, 'base-macos'), isFalse);
      },
    );

    test('returns false on empty output', () {
      expect(hasExactVmName('', 'base-macos'), isFalse);
    });
  });

  group('checkTartBaseImage', () {
    late Logger logger;

    setUp(() {
      logger = Logger.standard();
    });

    test(
      'returns true when tart list succeeds (exitCode 0) and contains base-macos',
      () async {
        late String receivedExecutable;
        late List<String> receivedArguments;
        late bool receivedRunInShell;

        Future<ProcessResult> mockRunner(
          String executable,
          List<String> arguments, {
          bool runInShell = false,
        }) async {
          receivedExecutable = executable;
          receivedArguments = arguments;
          receivedRunInShell = runInShell;
          return ProcessResult(0, 0, 'base-macos\n', '');
        }

        final result = await checkTartBaseImage(
          logger,
          processRunner: mockRunner,
        );
        expect(result, isTrue);
        expect(receivedExecutable, equals('tart'));
        expect(
          receivedArguments,
          equals(['list', '--source', 'local', '--quiet']),
        );
        expect(receivedRunInShell, isTrue);
      },
    );

    test('returns false when tart list exits with non-zero code', () async {
      Future<ProcessResult> mockRunner(
        String executable,
        List<String> arguments, {
        bool runInShell = false,
      }) async {
        return ProcessResult(1, 1, 'base-macos', 'tart: command failed');
      }

      final result = await checkTartBaseImage(
        logger,
        processRunner: mockRunner,
      );
      expect(result, isFalse);
    });

    test(
      'returns false when tart list succeeds but only contains base-macos-old',
      () async {
        Future<ProcessResult> mockRunner(
          String executable,
          List<String> arguments, {
          bool runInShell = false,
        }) async {
          return ProcessResult(0, 0, 'base-macos-old\n', '');
        }

        final result = await checkTartBaseImage(
          logger,
          processRunner: mockRunner,
        );
        expect(result, isFalse);
      },
    );

    test('returns false when tart is unavailable', () async {
      Future<ProcessResult> mockRunner(
        String executable,
        List<String> arguments, {
        bool runInShell = false,
      }) async {
        throw ProcessException(executable, arguments);
      }

      final result = await checkTartBaseImage(
        logger,
        processRunner: mockRunner,
      );
      expect(result, isFalse);
    });
  });
}
