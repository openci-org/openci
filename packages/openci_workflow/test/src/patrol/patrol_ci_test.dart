import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  late Directory workspace;
  late OpenCI ci;
  late Uri envWorkflow;

  setUpAll(() async {
    final library = await Isolate.resolvePackageUri(
      Uri.parse('package:openci_workflow/openci_workflow.dart'),
    );
    envWorkflow = library!.resolve('../test/fixtures/run_patrol_with_env.dart');
    workspace = await Directory.systemTemp.createTemp('openci-patrol-test-');
    final cli = Directory('${workspace.path}/fixture_cli');
    await Directory('${cli.path}/bin').create(recursive: true);
    await File('${cli.path}/pubspec.yaml').writeAsString('''
name: patrol_cli
environment:
  sdk: ^3.11.5
''');
    await File('${cli.path}/bin/main.dart').writeAsString('''
import 'dart:convert';
import 'dart:io';
void main(List<String> args) {
  const option = '--dart-define-from-file=';
  final files = args.where((arg) => arg.startsWith(option));
  File('invocation.json').writeAsStringSync(jsonEncode({
    'args': args,
    'cwd': Directory.current.path,
    if (files.isNotEmpty)
      'defines': jsonDecode(
        File(files.single.substring(option.length)).readAsStringSync(),
      ),
  }));
  stdout.writeln('Patrol fixture stdout');
  stderr.writeln('Patrol fixture stderr');
  if (args.contains('--fixture-fail')) exitCode = 23;
}
''');
    for (final dir in ['', 'apps/mobile', 'apps/other app']) {
      final project = Directory('${workspace.path}/$dir');
      await project.create(recursive: true);
      await File('${project.path}/pubspec.yaml').writeAsString('''
name: patrol_workflow_fixture
environment:
  sdk: ^3.11.5
dependencies:
  patrol_cli:
    path: ${dir.isEmpty ? '' : '../../'}fixture_cli
''');
      final result = await Process.run(
        Platform.resolvedExecutable,
        ['pub', 'get', '--offline'],
        workingDirectory: project.path,
      );
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    }
    ci = OpenCI(
      workflowName: 'Patrol test',
      ciTriggers: const [],
      workspacePath: workspace.path,
      currentWorkingDirectory: 'apps/mobile',
    );
  });
  tearDownAll(() => workspace.delete(recursive: true));

  Future<Map<String, dynamic>> invocation(String dir) async =>
      jsonDecode(
            await File('${workspace.path}/$dir/invocation.json').readAsString(),
          )
          as Map<String, dynamic>;

  Future<ProcessResult> runWithEnv(
    Map<String, String> env, {
    List<String> arguments = const [],
  }) async => Process.run(
    Platform.resolvedExecutable,
    [
      '--packages=${(await Isolate.packageConfig)!.toFilePath()}',
      envWorkflow.toFilePath(),
      ...arguments,
    ],
    workingDirectory: '${workspace.path}/apps/mobile',
    environment: {
      for (final entry in Platform.environment.entries)
        if (!entry.key.startsWith('PATROL_FIXTURE_')) entry.key: entry.value,
      ...env,
    },
    includeParentEnvironment: false,
  );

  test(
    'uses the project CLI and inherits or overrides the workflow directory',
    () async {
      for (final (dir, expectedDir) in [
        (null, 'apps/mobile'),
        ('apps/other app', 'apps/other app'),
        ('', ''),
        (null, 'apps/mobile'),
      ]) {
        await ci.patrol.test(device: 'emulator-5554', dir: dir);
        final actual = await invocation(expectedDir);
        expect(actual['args'], ['test', '--device', 'emulator-5554']);
        expect(
          actual['cwd'],
          await Directory(
            '${workspace.path}/$expectedDir',
          ).resolveSymbolicLinks(),
        );
      }
    },
  );

  test('forwards targets and extra options without shell expansion', () async {
    const literal =
        r'''space ' "$OPENCI_PATROL_TEST" `printf expanded` $(printf expanded); echo injected''';
    await ci.patrol.test(
      device: 'iPhone 17 Pro',
      targets: ['patrol_test/first_test.dart', 'patrol_test/$literal.dart'],
      verbose: true,
      additionalArguments: ['--flavor', literal, '--tags', 'smoke && !slow'],
    );
    expect((await invocation('apps/mobile'))['args'], [
      '--verbose',
      'test',
      '--device',
      'iPhone 17 Pro',
      '--target',
      'patrol_test/first_test.dart',
      '--target',
      'patrol_test/$literal.dart',
      '--flavor',
      literal,
      '--tags',
      'smoke && !slow',
    ]);
  });

  test('nonzero child exit throws while allowing finally cleanup', () async {
    var cleanedUp = false;
    Future<void> run() async {
      try {
        await ci.patrol.test(
          device: 'emulator-5554',
          additionalArguments: [
            '--fixture-fail',
            '--dart-define=TOKEN=private-value',
          ],
        );
      } finally {
        cleanedUp = true;
      }
    }

    await expectLater(
      run(),
      throwsA(
        isA<ProcessException>()
            .having((error) => error.errorCode, 'exit code', 23)
            .having(
              (error) => error.toString(),
              'diagnostic',
              isNot(contains('private-value')),
            ),
      ),
    );
    expect(cleanedUp, isTrue);
    // The parent process stays alive and can run another test.
    await ci.patrol.test(device: 'emulator-5554');
  });

  test('passes env by file and removes it on success and failure', () async {
    const values = {
      'PATROL_FIXTURE_EMAIL': 'tester@example.test',
      'PATROL_FIXTURE_PASSWORD': 'a "quoted" value, with=equals\n次の行',
    };
    const option = '--dart-define-from-file=';
    for (final extra in [
      <String>[],
      ['--fixture-fail'],
    ]) {
      final result = await runWithEnv(values, arguments: extra);
      expect(
        result.exitCode,
        extra.isEmpty ? 0 : isNot(0),
        reason: result.stderr.toString(),
      );
      final call = await invocation('apps/mobile');
      expect(call['defines'], values);
      final args = (call['args'] as List).cast<String>();
      expect(args, [
        'test',
        '--device',
        'device',
        startsWith(option),
        ...extra,
      ]);
      for (final value in values.values) {
        expect(args.join(' '), isNot(contains(value)));
        expect('${result.stdout}${result.stderr}', isNot(contains(value)));
      }
      final file = File(args[3].substring(option.length));
      expect(await file.parent.exists(), isFalse);
    }
  });

  test('rejects missing and empty env secrets before running Patrol', () async {
    for (final password in [null, '']) {
      final result = await runWithEnv({
        'PATROL_FIXTURE_EMAIL': 'tester@example.test',
        'PATROL_FIXTURE_PASSWORD': ?password,
      });
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains("Secret 'PATROL_FIXTURE_PASSWORD'"));
      expect(result.stdout, isNot(contains('Patrol fixture stdout')));
    }
  });

  test(
    'process startup failures also throw without echoing extra options',
    () async {
      await expectLater(
        ci.patrol.test(
          dir: 'does-not-exist',
          device: 'emulator-5554',
          additionalArguments: ['--dart-define=TOKEN=private-value'],
        ),
        throwsA(
          isA<ProcessException>().having(
            (error) => error.toString(),
            'diagnostic',
            isNot(contains('private-value')),
          ),
        ),
      );
    },
  );

  test('waits for the CLI before completing', () async {
    final completed = Completer<int>();
    final patrol = PatrolCI(
      (_) => workspace.path,
      processRunner: (_, _, {required workingDirectory}) => completed.future,
    );
    var finished = false;
    final future = patrol.test(device: 'device').then((_) => finished = true);
    await Future<void>.value();
    expect(finished, isFalse);
    completed.complete(0);
    await future;
    expect(finished, isTrue);
  });

  test('rejects empty device or target without starting a process', () async {
    final patrol = PatrolCI(
      (_) => workspace.path,
      processRunner: (_, _, {required workingDirectory}) async {
        fail('Invalid options must not start Patrol.');
      },
    );
    for (final run in [
      () => patrol.test(device: ''),
      () => patrol.test(device: ' '),
      () => patrol.test(device: 'device', targets: [' ']),
      () => patrol.test(device: 'device', targets: ['test.dart', '']),
    ]) {
      await expectLater(run(), throwsArgumentError);
    }
  });
}
