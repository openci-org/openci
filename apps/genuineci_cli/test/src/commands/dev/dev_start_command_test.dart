import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/src/commands/dev/dev_start_command.dart';
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
  }) {
    final runner = CommandRunner<int>('genuineci', 'CLI tool')
      ..addCommand(
        DevStartCommand(
          logger: _RecordingLogger(),
          projectRootFinder: () => tempDirectory,
          tartBaseImageChecker: (_) async => true,
          dockerComposeStarter: (_, _) async => true,
          orchardContextSetup: (_) async => true,
          localDataSeeder: (_) async {
            onSeed();
            return seedSucceeds;
          },
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

    final result = await runStart(
      shouldSeed: true,
      seedSucceeds: false,
      onSeed: () => seedCallCount++,
    );

    expect(result, equals(1));
    expect(seedCallCount, equals(1));
  });
}
