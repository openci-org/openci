import 'dart:io';

import 'package:genuine_ci/genuine_ci.dart';
import 'package:test/test.dart';

void main() {
  group('runCommand', () {
    test('completes when the command exits 0', () async {
      await runCommand(
        'echo hello',
        workingDirectory: Directory.systemTemp.path,
      );
    });

    test('runs the command in workingDirectory', () async {
      final dir = await Directory.systemTemp.createTemp('genuine_ci_test_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      await runCommand('pwd > pwd.txt', workingDirectory: dir.path);

      final output = File(
        '${dir.path}${Platform.pathSeparator}pwd.txt',
      ).readAsStringSync().trim();
      expect(
        await Directory(output).resolveSymbolicLinks(),
        await dir.resolveSymbolicLinks(),
      );
    });
  });
}
