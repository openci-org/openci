import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  late _ReleaseEnvironment environment;

  setUp(() async => environment = await _ReleaseEnvironment.create());
  tearDown(() => environment.workspace.delete(recursive: true));

  group('ShorebirdCI.releaseIos', () {
    for (final (method, profileType, archiveMethod) in [
      (IosDistributionMethod.appStore, 'IOS_APP_STORE', 'app-store'),
      (IosDistributionMethod.adHoc, 'IOS_APP_ADHOC', 'ad-hoc'),
    ]) {
      test('prepares $method signing and returns the exported IPA', () async {
        final ipaPath = await environment.release(distributionMethod: method);

        expect(ipaPath, startsWith('/'));
        expect(await File(ipaPath).readAsString(), 'new IPA');
        final signing = environment.arguments.singleWhere(
          (args) => args.contains('fetch-signing-files'),
        );
        expect(
          signing[signing.indexOf('fetch-signing-files') + 1],
          'org.example.app',
        );
        expect(signing[signing.indexOf('--type') + 1], profileType);
        final profiles = environment.arguments.singleWhere(
          (args) => args.contains('use-profiles'),
        );
        expect(
          profiles[profiles.indexOf('--archive-method') + 1],
          archiveMethod,
        );
        final exportPath =
            profiles[profiles.indexOf('--export-options-plist') + 1];
        expect(
          environment.arguments.singleWhere((args) => args.first == 'plutil'),
          [
            'plutil',
            '-replace',
            'manageAppVersionAndBuildNumber',
            '-bool',
            'NO',
            exportPath,
          ],
        );
        expect(environment.releaseArguments, [
          'shorebird',
          'release',
          'ios',
          '--flutter-version',
          '3.47.7',
          '--export-options-plist',
          exportPath,
        ]);
        expect(
          environment.arguments.indexWhere((args) => args.first == 'plutil'),
          lessThan(environment.arguments.indexOf(environment.releaseArguments)),
        );
        expect(environment.commands.join('\n'), isNot(contains('test-token')));
        expect(
          environment.commands.join('\n'),
          isNot(contains('TEST_ASC_KEY')),
        );
        expect(
          environment.commands.join('\n'),
          isNot(contains('TEST_CERT_KEY')),
        );
        expect(await environment.releaseTemporaryDirectories(), isEmpty);
      });
    }

    test('releases a fresh checkout without running system Flutter', () async {
      environment.beforeRun = (index) async {
        if (environment.commands[index].startsWith(
          'CI=true shorebird release ios',
        )) {
          expect(
            await File(
              '${environment.workspace.path}/apps/dashboard/ios/Flutter/Generated.xcconfig',
            ).exists(),
            isFalse,
          );
        }
      };

      final path = await environment.release();

      expect(await File(path).readAsString(), 'new IPA');
      expect(
        environment.arguments.map((args) => args.first),
        isNot(contains('flutter')),
      );
      expect(environment.commands.join('\n'), isNot(contains('flutter build')));
    });

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test(
        'preserves build arguments and resolves the directory: $dir',
        () async {
          const define =
              r'''hello' "$SHOREBIRD_TOKEN" `printf expanded` $(printf expanded),end''';
          const arguments = [
            '--target',
            'lib/main dev.dart',
            '--build-number=42',
          ];
          environment.buildDirectory = 'output with spaces';

          final ipaPath = await environment.release(
            bundleId: 'org.example.app.dev',
            dir: dir,
            flavor: 'dev',
            dartDefines: {'MESSAGE': define},
            additionalArguments: arguments,
          );

          final appDirectory = dir == ''
              ? environment.workspace.path
              : '${environment.workspace.path}/${dir ?? 'apps/dashboard'}';
          expect(environment.workingDirectories.toSet(), {appDirectory});
          expect(
            await File(ipaPath).resolveSymbolicLinks(),
            await File(
              '$appDirectory/output with spaces/ios/ipa/app.ipa',
            ).resolveSymbolicLinks(),
          );
          final release = environment.releaseArguments;
          expect(release[release.indexOf('--flavor') + 1], 'dev');
          expect(release.sublist(release.indexOf('--') + 1), [
            '--dart-define=MESSAGE=$define',
            ...arguments,
          ]);
          final signing = environment.arguments.singleWhere(
            (args) => args.contains('fetch-signing-files'),
          );
          expect(
            signing[signing.indexOf('fetch-signing-files') + 1],
            'org.example.app.dev',
          );
        },
      );
    }

    test('passes dry-run to Shorebird and still returns an IPA', () async {
      final path = await environment.release(
        dryRun: true,
        additionalArguments: ['--build-name=1.2.3'],
      );

      expect(await File(path).readAsString(), 'new IPA');
      final release = environment.releaseArguments;
      expect(release.indexOf('--dry-run'), lessThan(release.indexOf('--')));
      expect(environment.arguments.first, isNot(contains('--dry-run')));
    });

    for (final bundleId in ['', '  ', 'org.example.*', 'org example']) {
      test('rejects an invalid bundle ID before signing: $bundleId', () async {
        await expectLater(
          environment.release(bundleId: bundleId),
          throwsArgumentError,
        );
        expect(environment.commands, isEmpty);
        expect(await environment.temporary.list().toList(), isEmpty);
      });
    }

    for (final version in ['', '  ']) {
      test(
        'rejects an empty Flutter version before preparing signing',
        () async {
          await expectLater(
            environment.release(flutterVersion: version),
            throwsArgumentError,
          );
          expect(environment.commands, isEmpty);
          expect(await environment.temporary.list().toList(), isEmpty);
        },
      );
    }

    for (final option in [
      '--',
      '--export-options-plist',
      '--export-options-plist=custom.plist',
      '--export-method',
      '--export-method=app-store',
      '--codesign',
      '--no-codesign',
      '--config-only',
      '--debug',
      '--profile',
      '--release',
      '--no-release',
      '--simulator',
      '--flavor',
      '--flavor=other',
    ]) {
      test('rejects managed options before side effects: $option', () async {
        await expectLater(
          environment.release(additionalArguments: [option]),
          throwsArgumentError,
        );
        expect(environment.commands, isEmpty);
        expect(await environment.temporary.list().toList(), isEmpty);
      });
    }

    for (final missing in ['token', 'cli', 'yaml']) {
      test('fails before signing when $missing is missing', () async {
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

    test('rejects invalid signing credentials before any build', () async {
      await expectLater(
        environment.release(privateKeyBase64: 'invalid!!!'),
        throwsFormatException,
      );
      expect(environment.arguments, isEmpty);
    });

    for (var failingStep = 0; failingStep < 8; failingStep++) {
      test('stops after step $failingStep fails', () async {
        final error = StateError('Step failed');
        environment.beforeRun = (index) async {
          if (index == failingStep) throw error;
        };

        await expectLater(environment.release(), throwsA(same(error)));

        expect(environment.commands, hasLength(failingStep + 1));
        expect(await environment.releaseTemporaryDirectories(), isEmpty);
      });
    }

    test('propagates Shorebird failure even if it produced an IPA', () async {
      environment.shorebirdExitCode = 42;

      await expectLater(
        environment.release(),
        throwsA(isA<ProcessException>().having((e) => e.errorCode, 'exit', 42)),
      );

      expect(environment.commands, hasLength(7));
      expect(await environment.releaseTemporaryDirectories(), isEmpty);
    });

    for (final configuration in ['missing', 'empty']) {
      test('rejects a release with $configuration build settings', () async {
        environment.configuration = configuration;

        await expectLater(
          environment.release(),
          throwsA(isA<ProcessException>()),
        );

        expect(await environment.releaseTemporaryDirectories(), isEmpty);
      });
    }

    for (final artifact in ['missing', 'old', 'empty', 'multiple']) {
      test('rejects successful CLI execution with $artifact IPA', () async {
        environment.artifact = artifact;

        await expectLater(environment.release(), throwsStateError);

        expect(await environment.releaseTemporaryDirectories(), isEmpty);
      });
    }

    test('selects the new IPA even if an older export exists', () async {
      environment.artifact = 'old-and-new';

      final path = await environment.release();

      expect(path, endsWith('/app.ipa'));
      expect(await File(path).readAsString(), 'new IPA');
    });

    test('supports an absolute Flutter build directory', () async {
      environment.buildDirectory = '${environment.workspace.path}/absolute out';

      final path = await environment.release();

      expect(path, '${environment.buildDirectory}/ios/ipa/app.ipa');
    });
  }, testOn: '!windows');
}

class _ReleaseEnvironment {
  _ReleaseEnvironment(this.workspace, this.temporary);

  final Directory workspace;
  final Directory temporary;
  final commands = <String>[];
  final workingDirectories = <String>[];
  final arguments = <List<String>>[];
  String buildDirectory = 'build';
  String configuration = 'valid';
  String artifact = 'new';
  String token = 'test-token';
  bool hasYaml = true;
  int shorebirdExitCode = 0;
  Future<void> Function(int index)? beforeRun;

  List<String> get releaseArguments =>
      arguments.singleWhere((args) => args.first == 'shorebird');

  Future<List<FileSystemEntity>> releaseTemporaryDirectories() async =>
      (await temporary.list().toList())
          .where((entry) => entry.path.contains('openci-shorebird-release-'))
          .toList();

  static Future<_ReleaseEnvironment> create() async {
    final workspace = await Directory.systemTemp.createTemp(
      "openci shorebird ' ",
    );
    final temporary = await Directory.fromUri(
      workspace.uri.resolve('temporary/'),
    ).create();
    final bin = await Directory.fromUri(workspace.uri.resolve('bin/')).create();
    for (final name in [
      'shorebird',
      'xcode-project',
      'keychain',
      'app-store-connect',
      'plutil',
    ]) {
      final executable = File.fromUri(bin.uri.resolve(name));
      await executable.writeAsString(r'''#!/bin/sh
set -eu
name=${0##*/}
printf '%s\000' "$name" "$@" > "$OPENCI_TEST_ARGUMENTS"
case "$name" in
  shorebird)
    test "$CI" = true
    test "$SHOREBIRD_TOKEN" = test-token
    test "$1" = release
    test "$2" = ios
    if [ "$OPENCI_TEST_CONFIGURATION" != missing ]; then
      mkdir -p ios/Flutter
      cp "$OPENCI_TEST_SETTINGS" ios/Flutter/Generated.xcconfig
    fi
    case "$OPENCI_TEST_ARTIFACT" in
      new|old-and-new|multiple)
        mkdir -p "$OPENCI_TEST_IPA_DIR"
        printf 'new IPA' > "$OPENCI_TEST_IPA_DIR/app.ipa"
        if [ "$OPENCI_TEST_ARTIFACT" = multiple ]; then
          printf 'other IPA' > "$OPENCI_TEST_IPA_DIR/other.ipa"
        fi ;;
      empty) mkdir -p "$OPENCI_TEST_IPA_DIR"; touch "$OPENCI_TEST_IPA_DIR/app.ipa" ;;
    esac
    exit "$OPENCI_TEST_SHOREBIRD_EXIT" ;;
esac
''');
      final result = await Process.run('chmod', ['700', executable.path]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
    }
    return _ReleaseEnvironment(workspace, temporary);
  }

  Future<String> release({
    String bundleId = 'org.example.app',
    IosDistributionMethod distributionMethod = IosDistributionMethod.appStore,
    String flutterVersion = '3.47.7',
    String? dir,
    String? flavor,
    Map<String, String> dartDefines = const {},
    List<String> additionalArguments = const [],
    bool dryRun = false,
    String? privateKeyBase64,
  }) async {
    final app = dir == ''
        ? workspace
        : Directory.fromUri(
            workspace.uri.resolve('${dir ?? 'apps/dashboard'}/'),
          );
    await Directory.fromUri(
      app.uri.resolve('ios/Runner.xcodeproj/'),
    ).create(recursive: true);
    if (hasYaml) {
      await File.fromUri(
        app.uri.resolve('shorebird.yaml'),
      ).writeAsString('app_id: test-app\n');
    }
    final settings = File.fromUri(workspace.uri.resolve('settings'));
    await settings.writeAsString(
      'FLUTTER_BUILD_DIR=${configuration == 'empty' ? '' : buildDirectory}\n',
    );
    if (artifact == 'old' || artifact == 'old-and-new') {
      final filename = artifact == 'old' ? 'app.ipa' : 'old.ipa';
      final ipa = File.fromUri(
        app.uri.resolve('$buildDirectory/ios/ipa/$filename'),
      );
      await ipa.create(recursive: true);
      await ipa.writeAsString('old IPA');
      await ipa.setLastModified(DateTime(2000));
    }
    final ci = OpenCI.forTesting(
      workspacePath: workspace.path,
      currentWorkingDirectory: 'apps/dashboard',
      commandRunner: (command, {required workingDirectory}) async {
        final index = commands.length;
        commands.add(command);
        workingDirectories.add(workingDirectory);
        await beforeRun?.call(index);
        final argumentsFile = File.fromUri(
          workspace.uri.resolve('arguments-$index'),
        );
        final result = await Process.run(
          '/bin/sh',
          ['-c', command],
          workingDirectory: workingDirectory,
          environment: {
            'PATH': '${workspace.path}/bin:/usr/bin:/bin',
            'SHOREBIRD_TOKEN': token,
            'OPENCI_TEST_ARGUMENTS': argumentsFile.path,
            'OPENCI_TEST_SETTINGS': settings.path,
            'OPENCI_TEST_CONFIGURATION': configuration,
            'OPENCI_TEST_IPA_DIR': '$buildDirectory/ios/ipa',
            'OPENCI_TEST_ARTIFACT': artifact,
            'OPENCI_TEST_SHOREBIRD_EXIT': '$shorebirdExitCode',
          },
        );
        if (await argumentsFile.exists()) {
          arguments.add(
            (await argumentsFile.readAsString()).split('\u0000')..removeLast(),
          );
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
      () => ci.shorebird.releaseIos(
        bundleId: bundleId,
        distributionMethod: distributionMethod,
        ascKeys: AppStoreConnectKeys(
          issuerId: 'test-issuer',
          keyId: 'TESTKEY',
          privateKeyBase64:
              privateKeyBase64 ?? base64Encode(utf8.encode('TEST_ASC_KEY')),
        ),
        certificatePrivateKey: 'TEST_CERT_KEY',
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
