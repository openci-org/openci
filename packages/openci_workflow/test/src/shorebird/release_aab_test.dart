import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  late _ReleaseEnvironment environment;

  setUp(() async => environment = await _ReleaseEnvironment.create());
  tearDown(() => environment.workspace.delete(recursive: true));

  group('ShorebirdCI.releaseAab', () {
    test(
      'builds an AAB with Shorebird and returns its absolute path',
      () async {
        final path = await environment.release();

        expect(path, startsWith('/'));
        expect(path, endsWith('/bundle/release/app-release.aab'));
        expect(await File(path).readAsString(), 'built AAB');
        expect(environment.arguments, [
          'release',
          'android',
          '--artifact',
          'aab',
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
            flavor: 'staging',
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
              '$appDirectory/build/app/outputs/bundle/stagingRelease/app-staging-release.aab',
            ).resolveSymbolicLinks(),
          );
          expect(environment.arguments, [
            'release',
            'android',
            '--artifact',
            'aab',
            '--flutter-version',
            'revision-with-quote\'s',
            '--flavor',
            'staging',
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

      expect(await File(path).readAsString(), 'built AAB');
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
      '--artifact=apk',
      '--debug',
      '--profile',
      '--release',
      '--no-release',
      '--flavor',
      '--flavor=other',
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
      test('propagates Shorebird failure even with a $artifact AAB', () async {
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

    for (final artifact in ['missing', 'empty', 'multiple']) {
      test('rejects successful CLI execution with $artifact AAB', () async {
        environment.artifact = artifact;

        await expectLater(environment.release(), throwsStateError);

        expect(await environment.temporary.list().toList(), isEmpty);
      });
    }

    test('accepts the bundle when Gradle reuses an unchanged build', () async {
      environment.artifact = 'cached';

      final path = await environment.release();

      expect(await File(path).readAsString(), 'cached AAB');
      expect((await File(path).lastModified()).year, 2000);
    });

    test('does not return a bundle from a different flavor', () async {
      environment.artifact = 'missing';

      await expectLater(
        environment.release(flavor: 'staging'),
        throwsStateError,
      );
    });

    test('supports a custom AAB filename in the selected variant', () async {
      const filename = "app with ' quotes.aab";
      environment.filename = filename;

      final path = await environment.release();

      expect(path, endsWith(filename));
      expect(await File(path).readAsString(), 'built AAB');
    });
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
  String? filename;
  String token = 'test-token';
  bool hasYaml = true;
  int shorebirdExitCode = 0;
  Future<void> Function(int index)? beforeRun;

  static Future<_ReleaseEnvironment> create() async {
    final workspace = await Directory.systemTemp.createTemp("openci aab ' ");
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
  new|multiple)
    mkdir -p "$OPENCI_TEST_AAB_DIR"
    printf 'built AAB' > "$OPENCI_TEST_AAB_DIR/$OPENCI_TEST_FILENAME"
    if [ "$OPENCI_TEST_ARTIFACT" = multiple ]; then
      printf 'other AAB' > "$OPENCI_TEST_AAB_DIR/other.aab"
    fi ;;
  empty)
    mkdir -p "$OPENCI_TEST_AAB_DIR"
    touch "$OPENCI_TEST_AAB_DIR/$OPENCI_TEST_FILENAME" ;;
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
    final variant = flavor == null ? 'release' : '${flavor}Release';
    final aabDirectory = 'build/app/outputs/bundle/$variant';
    final aabName =
        filename ??
        (flavor == null ? 'app-release.aab' : 'app-$flavor-release.aab');
    if (artifact == 'cached') {
      final file = File('${app.path}/$aabDirectory/$aabName');
      await file.create(recursive: true);
      await file.writeAsString('cached AAB');
      await file.setLastModified(DateTime(2000));
    }
    final otherVariant = flavor == null ? 'otherRelease' : 'release';
    final otherBundle = File(
      '${app.path}/build/app/outputs/bundle/$otherVariant/other.aab',
    );
    await otherBundle.create(recursive: true);
    await otherBundle.writeAsString('another variant');
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
            'OPENCI_TEST_AAB_DIR': aabDirectory,
            'OPENCI_TEST_FILENAME': aabName,
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
      () => ci.shorebird.releaseAab(
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
