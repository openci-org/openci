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

  test(
    'readWorkspaceDirectories combines package roots and descendants',
    () async {
      await addDirectory('apps/dashboard/lib/src');
      await addDirectory('apps/dashboard/android/app/src/main');
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
          'apps/dashboard/lib/src',
          'apps/dashboard/android',
          'apps/dashboard/android/app',
          'apps/dashboard/android/app/src',
          'apps/dashboard/android/app/src/main',
          'apps/dashboard/assets',
          'packages/core',
          'packages/core/test',
          'packages/empty',
        ]),
      );
    },
  );

  group('readDirectoryPaths', () {
    test('includes an empty starting directory', () async {
      final directory = await addDirectory('apps/empty');

      expect(await readDirectoryPaths(directory, workspaceRoot: root), [
        'apps/empty',
      ]);
    });

    test('represents the workspace root as a relative dot path', () async {
      expect(await readDirectoryPaths(root, workspaceRoot: root), ['.']);
    });

    test('collects nested relative paths and ignores files', () async {
      final directory = await addDirectory('apps/dashboard');
      await addDirectory('apps/dashboard/android/app/src/main');
      await addDirectory('apps/dashboard/lib');
      await File(p.join(directory.path, 'pubspec.yaml')).writeAsString('');
      await File(
        p.join(directory.path, 'android/app/build.gradle.kts'),
      ).writeAsString('');

      expect(
        await readDirectoryPaths(directory, workspaceRoot: root),
        unorderedEquals([
          'apps/dashboard',
          'apps/dashboard/android',
          'apps/dashboard/android/app',
          'apps/dashboard/android/app/src',
          'apps/dashboard/android/app/src/main',
          'apps/dashboard/lib',
        ]),
      );
    });

    test(
      'excludes hidden directories, build outputs and dependencies',
      () async {
        final directory = await addDirectory('apps/dashboard');
        await addDirectory('apps/dashboard/lib/src');
        for (final name in [
          '.dart_tool',
          '.git',
          '.vscode',
          'build',
          'coverage',
          'node_modules',
          'Pods',
          'ephemeral',
          'xcuserdata',
        ]) {
          await addDirectory('apps/dashboard/$name/ignored');
          await addDirectory('apps/dashboard/lib/$name/ignored');
        }

        expect(
          await readDirectoryPaths(directory, workspaceRoot: root),
          unorderedEquals([
            'apps/dashboard',
            'apps/dashboard/lib',
            'apps/dashboard/lib/src',
          ]),
        );
      },
    );

    test(
      'excludes symbolic links and directory cycles',
      () async {
        final directory = await addDirectory('apps/dashboard');
        await addDirectory('apps/dashboard/lib');
        await Link(p.join(directory.path, 'linked')).create('lib');
        await Link(p.join(directory.path, 'lib/cycle')).create('..');

        expect(
          await readDirectoryPaths(directory, workspaceRoot: root),
          unorderedEquals(['apps/dashboard', 'apps/dashboard/lib']),
        );
      },
      skip: Platform.isWindows
          ? 'Creating symbolic links requires privileges on Windows.'
          : false,
    );

    test('propagates filesystem errors for a missing directory', () async {
      await expectLater(
        readDirectoryPaths(
          Directory(p.join(root.path, 'missing')),
          workspaceRoot: root,
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
