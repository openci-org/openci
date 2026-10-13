import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  late _ReleaseEnvironment environment;

  setUp(() async => environment = await _ReleaseEnvironment.create());
  tearDown(() => environment.workspace.delete(recursive: true));

  group('ShorebirdCI.releaseApk', () {
    test(
      'builds an APK with Shorebird and returns its absolute path',
      () async {
        final path = await environment.release();

        expect(path, startsWith('/'));
        expect(path, endsWith('/flutter-apk/app-release.apk'));
        expect(await File(path).readAsString(), 'built APK');
        expect(environment.arguments, [
          'release',
          'android',
          '--artifact',
          'apk',
          '--flutter-version',
          '3.47.7',
        ]);
        expect(environment.commands.join('\n'), isNot(contains('test-token')));
        expect(
          environment.commands.join('\n'),
          isNot(contains('flutter build')),
        );
        expect(await environment.temporary.list().toList(), isEmpty);
      },
    );

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test(
        'preserves shell arguments and the workflow directory: $dir',
        () async {
          const define =
              r'''hello' "$SHOREBIRD_TOKEN" `echo expanded` $(echo expanded)''';
          const arguments = [
            '--target',
            'lib/main dev.dart',
            '--build-number=42',
          ];

          final path = await environment.release(
            dir: dir,
            flavor: 'stagingProd',
            flutterVersion: 'revision-with-quote\'s',
            dartDefines: {'MESSAGE': define},
            additionalArguments: arguments,
          );

          final appDirectory = dir == ''
              ? environment.workspace.path
              : '${environment.workspace.path}/${dir ?? 'apps/dashboard'}';
          expect(environment.workingDirectories.toSet(), {appDirectory});
          expect(
            await File(path).resolveSymbolicLinks(),
            await File(
              '$appDirectory/build/app/outputs/flutter-apk/app-stagingprod-release.apk',
            ).resolveSymbolicLinks(),
          );
          expect(environment.arguments, [
            'release',
            'android',
            '--artifact',
            'apk',
            '--flutter-version',
            'revision-with-quote\'s',
            '--flavor',
            'stagingProd',
            '--',
            '--dart-define=MESSAGE=$define',
            ...arguments,
          ]);
        },
      );
    }

    test('passes dry-run to Shorebird before Flutter arguments', () async {
      final path = await environment.release(
        dryRun: true,
        additionalArguments: ['--build-name=1.2.3'],
      );

      expect(await File(path).readAsString(), 'built APK');
      expect(
        environment.arguments.indexOf('--dry-run'),
        lessThan(environment.arguments.indexOf('--')),
      );
    });

    for (final version in ['', '  ']) {
      test('rejects empty Flutter versions before running commands', () async {
        await expectLater(
          environment.release(flutterVersion: version),
          throwsArgumentError,
        );
        expect(environment.commands, isEmpty);
        expect(await environment.temporary.list().toList(), isEmpty);
      });
    }

    for (final option in [
      '--',
      '--artifact',
      '--artifact=aab',
      '--debug',
      '--profile',
      '--release',
      '--no-release',
      '--flavor',
      '--flavor=other',
      '--split-per-abi',
      '--split-per-abi=true',
      '--no-split-per-abi',
    ]) {
      test(
        'rejects managed options before running commands: $option',
        () async {
          await expectLater(
            environment.release(additionalArguments: [option]),
            throwsArgumentError,
          );
          expect(environment.commands, isEmpty);
          expect(await environment.temporary.list().toList(), isEmpty);
        },
      );
    }

    for (final missing in ['token', 'cli', 'yaml']) {
      test('fails before building when $missing is missing', () async {
        environment.token = missing == 'token' ? '' : 'test-token';
        environment.hasYaml = missing != 'yaml';
        if (missing == 'cli') {
          await File('${environment.workspace.path}/bin/shorebird').delete();
        }

        await expectLater(
          environment.release(),
          throwsA(isA<ProcessException>()),
        );

        expect(environment.commands, hasLength(1));
        expect(await environment.temporary.list().toList(), isEmpty);
      });
    }

    for (var failingStep = 0; failingStep < 3; failingStep++) {
      test('propagates failure at step $failingStep and cleans up', () async {
        final error = StateError('Step failed');
        environment.beforeRun = (index) async {
          if (index == failingStep) throw error;
        };

        await expectLater(environment.release(), throwsA(same(error)));

        expect(environment.commands, hasLength(failingStep + 1));
        expect(await environment.temporary.list().toList(), isEmpty);
      });
    }

    for (final artifact in ['new', 'cached']) {
      test('propagates Shorebird failure even with a $artifact APK', () async {
        environment.artifact = artifact;
        environment.shorebirdExitCode = 42;

        await expectLater(
          environment.release(),
          throwsA(
            isA<ProcessException>().having((e) => e.errorCode, 'exit', 42),
          ),
        );

        expect(await environment.temporary.list().toList(), isEmpty);
      });
    }

    for (final artifact in ['missing', 'empty', 'directory']) {
      test('rejects successful CLI execution with $artifact APK', () async {
        environment.artifact = artifact;

        await expectLater(environment.release(), throwsStateError);

        expect(await environment.temporary.list().toList(), isEmpty);
      });
    }

    test('accepts the APK when Gradle reuses an unchanged build', () async {
      environment.artifact = 'cached';

      final path = await environment.release();

      expect(await File(path).readAsString(), 'cached APK');
      expect((await File(path).lastModified()).year, 2000);
    });

    test(
      'does not return another flavor, build mode, split APK or AAB',
      () async {
        environment.artifact = 'missing';

        await expectLater(
          environment.release(flavor: 'stagingProd'),
          throwsStateError,
        );

        expect(await environment.temporary.list().toList(), isEmpty);
      },
    );
  }, testOn: '!windows');
}

class _ReleaseEnvironment {
  _ReleaseEnvironment(this.workspace, this.temporary);

  final Directory workspace;
  final Directory temporary;
  final commands = <String>[];
  final workingDirectories = <String>[];
  List<String> arguments = [];
  String artifact = 'new';
  String token = 'test-token';
  bool hasYaml = true;
  int shorebirdExitCode = 0;
  Future<void> Function(int index)? beforeRun;

  static Future<_ReleaseEnvironment> create() async {
    final workspace = await Directory.systemTemp.createTemp("openci apk ' ");
    final temporary = await Directory.fromUri(
      workspace.uri.resolve('temporary/'),
    ).create();
    final bin = await Directory.fromUri(workspace.uri.resolve('bin/')).create();
    final executable = File.fromUri(bin.uri.resolve('shorebird'));
    await executable.writeAsString(r'''#!/bin/sh
set -eu
test "$CI" = true
test "$SHOREBIRD_TOKEN" = test-token
printf '%s\000' "$@" > "$OPENCI_TEST_ARGUMENTS"
case "$OPENCI_TEST_ARTIFACT" in
  new)
    printf 'built APK' > "$OPENCI_TEST_APK_PATH" ;;
  empty)
    touch "$OPENCI_TEST_APK_PATH" ;;
  directory)
    mkdir "$OPENCI_TEST_APK_PATH" ;;
esac
exit "$OPENCI_TEST_SHOREBIRD_EXIT"
''');
    final result = await Process.run('chmod', ['700', executable.path]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    return _ReleaseEnvironment(workspace, temporary);
  }

  Future<String> release({
    String flutterVersion = '3.47.7',
    String? dir,
    String? flavor,
    Map<String, String> dartDefines = const {},
    List<String> additionalArguments = const [],
    bool dryRun = false,
  }) async {
    final app = dir == ''
        ? workspace
        : Directory.fromUri(
            workspace.uri.resolve('${dir ?? 'apps/dashboard'}/'),
          );
    await app.create(recursive: true);
    if (hasYaml) {
      await File.fromUri(
        app.uri.resolve('shorebird.yaml'),
      ).writeAsString('app_id: test-app\n');
    }
    final apkDirectory = 'build/app/outputs/flutter-apk';
    final apkName = flavor == null
        ? 'app-release.apk'
        : 'app-${flavor.toLowerCase()}-release.apk';
    final apk = File('${app.path}/$apkDirectory/$apkName');
    await apk.parent.create(recursive: true);
    if (artifact == 'cached') {
      await apk.writeAsString('cached APK');
      await apk.setLastModified(DateTime(2000));
    }
    for (final filename in [
      flavor == null ? 'app-other-release.apk' : 'app-release.apk',
      'app-debug.apk',
      'app-stagingprod-debug.apk',
      'app-arm64-v8a-release.apk',
      'app-stagingprod-arm64-v8a-release.apk',
    ]) {
      await File(
        '${app.path}/$apkDirectory/$filename',
      ).writeAsString('another APK');
    }
    final bundle = File(
      '${app.path}/build/app/outputs/bundle/release/app-release.aab',
    );
    await bundle.create(recursive: true);
    await bundle.writeAsString('built AAB');
    final argumentsFile = File.fromUri(workspace.uri.resolve('arguments'));
    final ci = OpenCI.forTesting(
      workspacePath: workspace.path,
      currentWorkingDirectory: 'apps/dashboard',
      commandRunner: (command, {required workingDirectory}) async {
        final index = commands.length;
        commands.add(command);
        workingDirectories.add(workingDirectory);
        await beforeRun?.call(index);
        final result = await Process.run(
          '/bin/sh',
          ['-c', command],
          workingDirectory: workingDirectory,
          environment: {
            'PATH': '${workspace.path}/bin:/usr/bin:/bin',
            'SHOREBIRD_TOKEN': token,
            'OPENCI_TEST_ARGUMENTS': argumentsFile.path,
            'OPENCI_TEST_APK_PATH': '$apkDirectory/$apkName',
            'OPENCI_TEST_ARTIFACT': artifact,
            'OPENCI_TEST_SHOREBIRD_EXIT': '$shorebirdExitCode',
          },
        );
        if (await argumentsFile.exists()) {
          arguments = (await argumentsFile.readAsString()).split('\u0000')
            ..removeLast();
        }
        if (result.exitCode != 0) {
          throw ProcessException(
            '/bin/sh',
            ['-c', command],
            '${result.stderr}',
            result.exitCode,
          );
        }
      },
    );
    return IOOverrides.runZoned(
      () => ci.shorebird.releaseApk(
        flutterVersion: flutterVersion,
        dir: dir,
        flavor: flavor,
        dartDefines: dartDefines,
        additionalArguments: additionalArguments,
        dryRun: dryRun,
      ),
      getSystemTempDirectory: () => temporary,
    );
  }
}
