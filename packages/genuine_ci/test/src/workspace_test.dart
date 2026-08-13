import 'dart:io';

import 'package:genuine_ci/genuine_ci.dart';
import 'package:test/test.dart';

void main() {
  group('Workspace.resolve', () {
    late Workspace workspace;

    setUp(() async {
      workspace = await Workspace.create();
    });

    tearDown(() async {
      final directory = Directory(workspace.path);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('returns workspace path when relative cwd is omitted', () {
      expect(workspace.resolve(), workspace.path);
    });

    test('returns workspace path when relative cwd is empty', () {
      expect(workspace.resolve(''), workspace.path);
    });

    test('joins relative cwd onto the workspace path', () {
      expect(
        workspace.resolve('apps/dashboard'),
        '${workspace.path}${Platform.pathSeparator}apps/dashboard',
      );
    });
  });
}
