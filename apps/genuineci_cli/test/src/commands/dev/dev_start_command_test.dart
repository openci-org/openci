import 'dart:io';

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

  test('reports projectRootNotFound before checking Tart', () async {
    final logger = _RecordingLogger();

    final result = await DevStartCommand(logger: logger).run();

    expect(result, equals(1));
    expect(logger.stdoutMessages, equals([t.dev.start.starting]));
    expect(logger.stderrMessages, equals([t.dev.start.projectRootNotFound]));
  });
}
