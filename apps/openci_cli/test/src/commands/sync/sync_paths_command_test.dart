import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:path/path.dart' as p;
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
  const previousSource = '// Previous workspace paths\n';
  late Directory root;
  late Directory workflows;
  late File pubspec;
  late File output;
  late _RecordingLogger logger;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('openci-sync-paths-');
    workflows = await Directory(p.join(root.path, 'openci')).create();
    pubspec = File(p.join(root.path, 'pubspec.yaml'));
    await pubspec.writeAsString('workspace: [apps/dashboard]\n');
    final member = File(p.join(root.path, 'apps/dashboard/pubspec.yaml'));
    await member.parent.create(recursive: true);
    await member.writeAsString('name: dashboard\n');
    output = File(p.join(workflows.path, 'generated', 'paths.g.dart'));
    await output.parent.create();
    await output.writeAsString(previousSource);
    logger = _RecordingLogger();
  });

  tearDown(() => root.delete(recursive: true));

  Future<int?> runSync({
    List<String> arguments = const [],
    Directory? workingDirectory,
  }) {
    final runner = CommandRunner<int>('genuineci', 'test')
      ..addCommand(
        SyncCommand(logger: logger, workingDirectory: workingDirectory ?? root),
      );
    return runner.run(['sync', '--paths', ...arguments]);
  }

  Future<void> expectPreserved() async {
    expect(await output.readAsString(), previousSource);
    expect(logger.stdoutMessages, isEmpty);
    expect(logger.stderrMessages, hasLength(1));
  }

  test('creates paths from a nested directory without login', () async {
    await output.delete();
    final nested = await Directory(
      p.join(root.path, 'apps/dashboard/lib/src'),
    ).create(recursive: true);
    await Directory(
      p.join(root.path, 'apps/dashboard/android/app'),
    ).create(recursive: true);
    for (final name in ['.dart_tool', 'build']) {
      await Directory(p.join(root.path, 'apps/dashboard', name)).create();
    }
    final secrets = File(p.join(workflows.path, 'generated', 'secrets.g.dart'));
    await secrets.writeAsString('// Existing secrets\n');

    expect(await runSync(workingDirectory: nested), 0);

    final source = await output.readAsString();
    expect(source, contains('abstract final class WorkspacePaths'));
    expect(
      source,
      contains(
        r'WorkspaceRoot$Apps$Dashboard get dashboard => '
        r'const WorkspaceRoot$Apps$Dashboard._("apps/dashboard");',
      ),
    );
    expect(
      source,
      contains(
        r'WorkspaceRoot$Apps$Dashboard$Lib get lib => '
        r'const WorkspaceRoot$Apps$Dashboard$Lib._("apps/dashboard/lib");',
      ),
    );
    expect(
      source,
      contains(
        'WorkspaceDirectory get src => const WorkspaceDirectory("apps/dashboard/lib/src");',
      ),
    );
    expect(
      source,
      contains(
        r'WorkspaceRoot$Apps$Dashboard$Android get android => '
        r'const WorkspaceRoot$Apps$Dashboard$Android._("apps/dashboard/android");',
      ),
    );
    expect(
      source,
      contains(
        'WorkspaceDirectory get app => const WorkspaceDirectory("apps/dashboard/android/app");',
      ),
    );
    for (final field in ['dartTool', 'build']) {
      expect(source, isNot(contains('get $field')));
    }
    expect(source, isNot(contains(root.path)));
    expect(await secrets.readAsString(), '// Existing secrets\n');
    expect(logger.stdoutMessages, [t.sync.paths.saved(path: output.path)]);
    expect(logger.stderrMessages, isEmpty);
  });

  test('creates single-package paths from a nested directory', () async {
    const rootPubspec = 'name: example\n';
    await pubspec.writeAsString(rootPubspec);
    await Directory(p.join(root.path, 'apps')).delete(recursive: true);
    final nested = await Directory(
      p.join(root.path, 'android/app'),
    ).create(recursive: true);
    await Directory(p.join(root.path, 'lib/src')).create(recursive: true);
    for (final name in ['.dart_tool', 'build', 'node_modules']) {
      await Directory(p.join(root.path, name)).create();
    }

    expect(await runSync(workingDirectory: nested), 0);

    final source = await output.readAsString();
    expect(source, contains("static const root = WorkspaceRoot._('.');"));
    expect(
      source,
      contains(r'get android => const WorkspaceRoot$Android._("android");'),
    );
    expect(
      source,
      contains('get app => const WorkspaceDirectory("android/app");'),
    );
    expect(source, contains(r'get lib => const WorkspaceRoot$Lib._("lib");'));
    expect(source, contains('get src => const WorkspaceDirectory("lib/src");'));
    expect(
      source,
      contains('get openci => const WorkspaceDirectory("openci");'),
    );
    for (final field in [
      'example',
      'apps',
      'dartTool',
      'build',
      'nodeModules',
    ]) {
      expect(source, isNot(contains('get $field =>')));
    }
    expect(source, isNot(contains(root.path)));
    expect(await pubspec.readAsString(), rootPubspec);
    expect(logger.stderrMessages, isEmpty);
    expect(await runSync(), 0);
    expect(await output.readAsString(), source);
  });

  test('preserves paths when the single-package name is missing', () async {
    await pubspec.writeAsString('publish_to: none\n');

    expect(await runSync(), 1);

    await expectPreserved();
    expect(
      logger.stderrMessages.single,
      contains('name must be a non-empty string'),
    );
  });

  test('preserves paths when an explicit workspace is invalid', () async {
    await pubspec.writeAsString('name: example\nworkspace: null\n');

    expect(await runSync(), 1);

    await expectPreserved();
    expect(logger.stderrMessages.single, contains('workspace must be a list'));
  });

  test(
    'updates paths after a package moves and produces stable output',
    () async {
      expect(await runSync(), 0);
      final moved = Directory(p.join(root.path, 'packages/dashboard'));
      await moved.parent.create();
      await Directory(p.join(root.path, 'apps/dashboard')).rename(moved.path);
      await pubspec.writeAsString('workspace: [packages/dashboard]\n');

      expect(await runSync(workingDirectory: workflows), 0);
      final source = await output.readAsString();
      expect(source, contains('get packages =>'));
      expect(
        source,
        contains(
          'get dashboard => const WorkspaceDirectory("packages/dashboard");',
        ),
      );
      expect(source, isNot(contains('apps/dashboard')));
      expect(await runSync(), 0);
      expect(await output.readAsString(), source);
    },
  );

  test(
    'generates the openci accessor for the workflow workspace package',
    () async {
      await pubspec.writeAsString('workspace: [apps/dashboard, openci]\n');
      await File(
        p.join(workflows.path, 'pubspec.yaml'),
      ).writeAsString('name: openci_workflows\n');

      expect(await runSync(workingDirectory: workflows), 0);

      expect(
        output.path,
        p.join(root.path, 'openci', 'generated', 'paths.g.dart'),
      );
      expect(
        await output.readAsString(),
        contains(
          'WorkspaceDirectory get openci => const WorkspaceDirectory("openci");',
        ),
      );
      expect(logger.stderrMessages, isEmpty);
    },
  );

  test('removes stale fields for an empty workspace', () async {
    await pubspec.writeAsString('workspace: []\n');

    expect(await runSync(), 0);

    expect(
      await output.readAsString(),
      contains("static const root = WorkspaceRoot._('.');"),
    );
    expect(await output.readAsString(), isNot(contains('get dashboard')));
  });

  test('reports a missing workflow directory without creating one', () async {
    await workflows.delete(recursive: true);

    expect(await runSync(), 1);

    expect(await workflows.exists(), isFalse);
    expect(logger.stderrMessages, [t.sync.paths.projectRootNotFound]);
  });

  test('preserves paths when a pubspec cannot be read', () async {
    final member = File(p.join(root.path, 'apps/dashboard/pubspec.yaml'));
    await member.delete();

    expect(await runSync(), 1);

    await expectPreserved();
    expect(logger.stderrMessages, [
      t.sync.paths.fileAccessFailed(path: member.path),
    ]);
  });

  test('does not mistake the SDK package for the workflow directory', () async {
    final sdk = await Directory(
      p.join(root.path, 'packages/openci'),
    ).create(recursive: true);
    await File(
      p.join(sdk.path, 'pubspec.yaml'),
    ).writeAsString('name: openci\n');

    expect(await runSync(workingDirectory: sdk), 0);

    expect(
      await output.readAsString(),
      contains('get dashboard => const WorkspaceDirectory("apps/dashboard");'),
    );
    expect(await File(p.join(sdk.path, 'paths.g.dart')).exists(), isFalse);
  });

  test('preserves paths when YAML is malformed', () async {
    await pubspec.writeAsString('workspace: [\n');

    expect(await runSync(), 1);

    await expectPreserved();
    expect(logger.stderrMessages.single, contains('invalid YAML'));
  });

  test('generates reserved package and subdirectory names', () async {
    await Directory(
      p.join(root.path, 'apps/dashboard'),
    ).rename(p.join(root.path, 'apps/class'));
    await pubspec.writeAsString('workspace: [apps/class]\n');
    final nested = await Directory(
      p.join(root.path, 'apps/class/lib/switch/team'),
    ).create(recursive: true);

    expect(await runSync(workingDirectory: nested), 0);

    final source = await output.readAsString();
    expect(
      source,
      contains(
        r'get class_ => const WorkspaceRoot$Apps$Class_._("apps/class");',
      ),
    );
    expect(
      source,
      contains(
        r'get switch_ => const WorkspaceRoot$Apps$Class_$Lib$Switch_._("apps/class/lib/switch");',
      ),
    );
    expect(
      source,
      contains(
        'get team => const WorkspaceDirectory("apps/class/lib/switch/team");',
      ),
    );
    expect(await nested.exists(), isTrue);
    expect(logger.stderrMessages, isEmpty);
    expect(await runSync(), 0);
    expect(await output.readAsString(), source);
  });

  test('preserves paths when escaped directory names collide', () async {
    for (final name in ['switch', 'switch_']) {
      await Directory(p.join(root.path, 'apps/dashboard', name)).create();
    }

    expect(await runSync(), 1);

    await expectPreserved();
    expect(logger.stderrMessages.single, contains('both map to "switch_"'));
  });

  test(
    'preserves paths when source generation rejects a directory name',
    () async {
      await Directory(
        p.join(root.path, 'apps/dashboard'),
      ).rename(p.join(root.path, 'apps/2dashboard'));
      await pubspec.writeAsString('workspace: [apps/2dashboard]\n');

      expect(await runSync(), 1);

      await expectPreserved();
      expect(
        logger.stderrMessages.single,
        contains('cannot be used as a Dart field'),
      );
    },
  );

  test('preserves paths when a package subdirectory name is invalid', () async {
    await Directory(p.join(root.path, 'apps/dashboard/___')).create();

    expect(await runSync(), 1);

    await expectPreserved();
    expect(
      logger.stderrMessages.single,
      contains('Directory "___" cannot be used as a Dart field'),
    );
  });

  test('uses directory names even when the package name differs', () async {
    await File(
      p.join(root.path, 'apps/dashboard/pubspec.yaml'),
    ).writeAsString('name: frontend\n');

    expect(await runSync(), 0);

    final source = await output.readAsString();
    expect(source, contains('get apps =>'));
    expect(
      source,
      contains('get dashboard => const WorkspaceDirectory("apps/dashboard");'),
    );
    expect(source, isNot(contains('frontend')));
  });

  test('reports a write failure and cleans up temporary files', () async {
    await output.delete();
    await Directory(output.path).create();
    final existing = File(p.join(output.path, 'keep.txt'));
    await existing.writeAsString('keep');

    expect(await runSync(), 1);

    expect(await existing.readAsString(), 'keep');
    expect(output.parent.listSync().map((entry) => entry.path), [output.path]);
    expect(logger.stdoutMessages, isEmpty);
    expect(logger.stderrMessages.single, contains('paths.g.dart'));
  });

  test('help describes generation without reading or writing files', () async {
    await pubspec.delete();
    final messages = <String>[];

    await runZoned(
      () => runSync(arguments: ['--help']),
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, message) => messages.add(message),
      ),
    );

    expect(messages.join('\n'), contains(t.sync.paths.description));
    expect(logger.stderrMessages, isEmpty);
    expect(await output.readAsString(), previousSource);
  });

  for (final arguments in [
    ['unexpected'],
    ['--output', 'elsewhere.dart'],
  ]) {
    test('rejects unsupported arguments: $arguments', () async {
      await expectLater(
        runSync(arguments: arguments),
        throwsA(isA<UsageException>()),
      );

      expect(await output.readAsString(), previousSource);
      expect(logger.stdoutMessages, isEmpty);
      expect(logger.stderrMessages, isEmpty);
    });
  }
}
