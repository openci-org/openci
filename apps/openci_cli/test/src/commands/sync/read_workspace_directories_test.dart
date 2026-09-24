import 'dart:io';

import 'package:openci_cli/src/commands/sync/read_workspace_directories.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('openci-directories-');
  });

  tearDown(() => root.delete(recursive: true));

  Future<Directory> addDirectory(String path) =>
      Directory(p.join(root.path, path)).create(recursive: true);

  test('includes package roots and only immediate subdirectories', () async {
    await addDirectory('apps/dashboard/lib/src');
    await addDirectory('apps/dashboard/assets');
    await addDirectory('packages/core/test');
    await addDirectory('packages/empty');
    await File(
      p.join(root.path, 'apps/dashboard/pubspec.yaml'),
    ).writeAsString('name: dashboard\n');

    expect(
      await readWorkspaceDirectories(root, [
        'apps/dashboard',
        'packages/core',
        'packages/empty',
      ]),
      unorderedEquals([
        'apps/dashboard',
        'apps/dashboard/lib',
        'apps/dashboard/assets',
        'packages/core',
        'packages/core/test',
        'packages/empty',
      ]),
    );
  });

  test('excludes hidden directories, build outputs and dependencies', () async {
    for (final name in [
      'lib',
      '.dart_tool',
      '.git',
      '.vscode',
      'build',
      'coverage',
      'node_modules',
      'Pods',
    ]) {
      await addDirectory('apps/dashboard/$name');
    }

    expect(
      await readWorkspaceDirectories(root, ['apps/dashboard']),
      unorderedEquals(['apps/dashboard', 'apps/dashboard/lib']),
    );
  });

  test(
    'excludes symbolic links to directories',
    () async {
      await addDirectory('apps/dashboard/lib');
      await Link(p.join(root.path, 'apps/dashboard/linked')).create('lib');

      expect(
        await readWorkspaceDirectories(root, ['apps/dashboard']),
        unorderedEquals(['apps/dashboard', 'apps/dashboard/lib']),
      );
    },
    skip: Platform.isWindows
        ? 'Creating symbolic links requires privileges on Windows.'
        : false,
  );
}
