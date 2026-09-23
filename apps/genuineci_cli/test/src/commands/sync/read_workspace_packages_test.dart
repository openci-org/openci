import 'dart:convert';
import 'dart:io';

import 'package:genuineci_cli/src/commands/sync/read_workspace_packages.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late File pubspec;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('genuineci-workspace-');
    pubspec = File(p.join(root.path, 'pubspec.yaml'));
    await pubspec.writeAsString('workspace: []\n');
  });

  tearDown(() => root.delete(recursive: true));

  group('findWorkspaceRoot', () {
    test(
      'finds the root from a package with the same name as openci',
      () async {
        final workflows = await Directory(p.join(root.path, 'openci')).create();
        final sdk = await Directory(
          p.join(root.path, 'packages/openci'),
        ).create(recursive: true);
        await File(
          p.join(sdk.path, 'pubspec.yaml'),
        ).writeAsString('name: openci');

        for (final start in [root, workflows, sdk, sdk.parent]) {
          expect(findWorkspaceRoot(start)?.path, root.path);
        }
      },
    );

    test('requires both a pubspec and a workflow directory', () async {
      expect(findWorkspaceRoot(root), isNull);
      await Directory(p.join(root.path, 'openci')).create();
      await pubspec.delete();

      expect(findWorkspaceRoot(root), isNull);
    });

    for (final directory in ['genuine_ci', '.openci']) {
      test('does not accept $directory as the workflow root marker', () async {
        await Directory(p.join(root.path, directory)).create();

        expect(findWorkspaceRoot(root), isNull);
      });
    }
  });

  Future<File> addPackage(String path, String content) async {
    final file = File(p.join(root.path, path, 'pubspec.yaml'));
    await file.parent.create(recursive: true);
    return file.writeAsString(content);
  }

  test('reads package names from workspace member pubspecs', () async {
    await pubspec.writeAsString('''
name: example
workspace:
  - apps/frontend # The directory name differs from the package name.
  - packages/openci_workflow
  - openci
''');
    await addPackage('apps/frontend', 'name: dashboard\n');
    await addPackage('packages/openci_workflow', "name: 'openci_workflow'\n");
    await addPackage('openci', 'name: openci_workflows\n');

    expect(await readWorkspacePackages(root), {
      'dashboard': 'apps/frontend',
      'openci_workflow': 'packages/openci_workflow',
      'openci_workflows': 'openci',
    });
  });

  test('allows an empty workspace', () async {
    expect(await readWorkspacePackages(root), isEmpty);
  });

  for (final content in ['', '[]', 'workspace: [\n']) {
    test('rejects an invalid root pubspec: ${jsonEncode(content)}', () async {
      await pubspec.writeAsString(content);

      await expectLater(
        readWorkspacePackages(root),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(pubspec.path),
          ),
        ),
      );
    });
  }

  for (final workspace in [
    null,
    'apps/dashboard',
    {},
    [42],
  ]) {
    test('rejects a missing or invalid workspace: $workspace', () async {
      await pubspec.writeAsString(jsonEncode({'workspace': workspace}));

      await expectLater(
        readWorkspacePackages(root),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('workspace must be a list'),
          ),
        ),
      );
    });
  }

  test('requires workspace to be declared', () async {
    await pubspec.writeAsString('name: example\n');

    await expectLater(readWorkspacePackages(root), throwsFormatException);
  });

  for (final path in ['', '../outside', '/tmp/package', r'C:\package']) {
    test('validates paths before reading package files: $path', () async {
      await pubspec.writeAsString(
        jsonEncode({
          'workspace': [path],
        }),
      );

      await expectLater(readWorkspacePackages(root), throwsFormatException);
    });
  }

  test('reports a missing root pubspec', () async {
    await pubspec.delete();

    await expectLater(
      readWorkspacePackages(root),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          pubspec.path,
        ),
      ),
    );
  });

  test('reports a missing member pubspec', () async {
    await pubspec.writeAsString('workspace: [apps/dashboard]\n');

    await expectLater(
      readWorkspacePackages(root),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.path,
          'path',
          p.join(root.path, 'apps/dashboard/pubspec.yaml'),
        ),
      ),
    );
  });

  for (final content in ['name: [\n', '[]', '{}', 'name: 42', 'name: ""']) {
    test('rejects an invalid package pubspec: $content', () async {
      await pubspec.writeAsString('workspace: [apps/dashboard]\n');
      final member = await addPackage('apps/dashboard', content);

      await expectLater(
        readWorkspacePackages(root),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(member.path),
          ),
        ),
      );
    });
  }

  test('reports both paths for duplicate package names', () async {
    await pubspec.writeAsString('workspace: [apps/first, apps/second]\n');
    await addPackage('apps/first', 'name: dashboard\n');
    await addPackage('apps/second', 'name: dashboard\n');

    await expectLater(
      readWorkspacePackages(root),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('dashboard'),
            contains('apps/first'),
            contains('apps/second'),
          ),
        ),
      ),
    );
  });
}
