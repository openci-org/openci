import 'dart:io';

import 'package:genuine_ci/genuine_ci.dart';
import 'package:test/test.dart';

void main() {
  group('GenuineCI.resolveWorkingDirectory', () {
    const workspacePath = '/tmp/genuine_ci_workspace';
    final genuineCI = GenuineCI.forTesting(workspacePath: workspacePath);

    test('returns workspace path when relative cwd is omitted', () {
      expect(genuineCI.resolveWorkingDirectory(), workspacePath);
    });

    test('returns workspace path when relative cwd is empty', () {
      expect(genuineCI.resolveWorkingDirectory(''), workspacePath);
    });

    test('joins relative cwd onto the workspace path', () {
      expect(
        genuineCI.resolveWorkingDirectory('apps/dashboard'),
        '$workspacePath${Platform.pathSeparator}apps/dashboard',
      );
    });
  });

  group('GenuineCI.createWorkspace', () {
    test('creates a temporary directory', () async {
      final path = await GenuineCI.createWorkspace();
      addTearDown(() async {
        final directory = Directory(path);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      expect(Directory(path).existsSync(), isTrue);
    });
  });
}
