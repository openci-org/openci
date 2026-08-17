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

  group('GenuineCI.init', () {
    test('initializes with default current directory as workspace', () async {
      final ci = await GenuineCI.init(
        workflowName: 'Test Workflow',
        ciTrigger: const CiTrigger.push(branch: 'main'),
      );

      expect(ci.workflowName, 'Test Workflow');
      expect(ci.workspacePath, Directory.current.path);
    });

    test('initializes with custom workspace path', () async {
      final customPath = '${Directory.systemTemp.path}/custom_workspace';
      final ci = await GenuineCI.init(
        workflowName: 'Test Workflow',
        ciTrigger: const CiTrigger.push(branch: 'main'),
        workspacePath: customPath,
      );

      expect(ci.workspacePath, customPath);
    });
  });
}
