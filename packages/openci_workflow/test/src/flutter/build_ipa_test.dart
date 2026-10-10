import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  late _BuildEnvironment environment;

  setUp(() async {
    environment = await _BuildEnvironment.create();
  });
  tearDown(() => environment.workspace.delete(recursive: true));

  group('buildIpa', () {
    test('exports a TestFlight IPA with App Store signing files', () async {
      final ipaPath = await environment.build(
        distributionMethod: IosDistributionMethod.appStore,
      );
      expect(ipaPath, startsWith('/'));
      expect(await File(ipaPath).readAsString(), 'test IPA');

      final signing = environment.arguments.singleWhere(
        (args) => args.contains('fetch-signing-files'),
      );
      expect(signing[signing.indexOf('--type') + 1], 'IOS_APP_STORE');

      final profiles = environment.arguments.singleWhere(
        (args) => args.contains('use-profiles'),
      );
      expect(profiles[profiles.indexOf('--archive-method') + 1], 'app-store');

      final build = environment.arguments.singleWhere(
        (args) => args.contains('ipa'),
      );
      expect(
        build[build.indexOf('--export-options-plist') + 1],
        profiles[profiles.indexOf('--export-options-plist') + 1],
      );
      expect(
        await File(
          '${environment.workspace.path}/apps/dashboard/build/ios/ipa/app.ipa',
        ).readAsString(),
        'test IPA',
      );
    });

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test('prepares signing and exports in the workflow directory: $dir', () async {
        const argument =
            r'''--dart-define=MESSAGE=hello' "$SECRET" `printf expanded` $(printf expanded)''';
        environment.flavor = 'dev';
        environment.configurations = ['Debug', 'Release-Dev'];
        environment.buildDirectory = 'output with spaces';

        final ipaPath = await environment.build(
          dir: dir,
          flavor: 'dev',
          additionalArguments: [argument, '--target', 'lib/main dev.dart'],
        );

        expect(environment.commands, hasLength(10));
        expect(environment.arguments.where((args) => args.isNotEmpty).toList(), [
          [
            'flutter',
            'build',
            'ios',
            '--flavor',
            'dev',
            argument,
            '--target',
            'lib/main dev.dart',
            '--release',
            '--config-only',
            '--no-codesign',
          ],
          ['xcodebuild', '-list', '-json', '-project', 'ios/Runner.xcodeproj'],
          [
            'xcode-project',
            'detect-bundle-id',
            '--project',
            'ios/Runner.xcodeproj',
            '--config',
            'Release-Dev',
            '--log-stream',
            'stderr',
          ],
          [
            'keychain',
            'initialize',
            '--path',
            '/tmp/openci-signing.keychain-db',
          ],
          [
            'app-store-connect',
            'fetch-signing-files',
            'org.example.app',
            '--issuer-id',
            'test-issuer',
            '--key-id',
            'TESTKEY',
            '--private-key',
            '@file:${environment.temporary.uri.resolve('openci-ios-signing/asc-private-key.p8').toFilePath()}',
            '--certificate-key',
            '@file:${environment.temporary.uri.resolve('openci-ios-signing/certificate-private-key.pem').toFilePath()}',
            '--type',
            'IOS_APP_ADHOC',
            '--create',
          ],
          [
            'keychain',
            'add-certificates',
            '--path',
            '/tmp/openci-signing.keychain-db',
          ],
          [
            'xcode-project',
            'use-profiles',
            '--project',
            'ios/*.xcodeproj',
            '--archive-method',
            'ad-hoc',
            '--export-options-plist',
            '/tmp/openci-export-options.plist',
          ],
          [
            'flutter',
            'build',
            'ipa',
            '--flavor',
            'dev',
            argument,
            '--target',
            'lib/main dev.dart',
            '--release',
            '--codesign',
            '--export-options-plist',
            '/tmp/openci-export-options.plist',
          ],
        ]);
        final relativeDirectory = dir ?? 'apps/dashboard';
        final expectedDirectory = relativeDirectory.isEmpty
            ? environment.workspace.path
            : '${environment.workspace.path}/$relativeDirectory';
        expect(environment.workingDirectories.toSet(), {expectedDirectory});
        expect(
          await File(ipaPath).resolveSymbolicLinks(),
          await File(
            '$expectedDirectory/output with spaces/ios/ipa/app.ipa',
          ).resolveSymbolicLinks(),
        );
        expect(
          await File(
            '$expectedDirectory/output with spaces/ios/ipa/app.ipa',
          ).readAsString(),
          'test IPA',
        );
        expect(
          environment.commands.join('\n'),
          isNot(contains('TEST_ASC_KEY')),
        );
        expect(
          environment.commands.join('\n'),
          isNot(contains('TEST_CERTIFICATE_KEY')),
        );
      });
    }

    for (final (flavor, configurations, expected)
        in <(String?, List<String>, String)>[
          (null, ['Debug', 'Release'], 'Release'),
          ('prod', ['Release', 'Release-PROD'], 'Release-PROD'),
          (
            'dev',
            ['Release', 'Development Release Dev'],
            'Development Release Dev',
          ),
          ('prod', ['Debug', 'Release'], 'Release'),
        ]) {
      test(
        'uses the generated flavor and release configuration: $flavor, $expected',
        () async {
          environment.flavor = flavor;
          environment.configurations = configurations;

          // No API flavor: Flutter can select one from the app's pubspec.
          await environment.build();

          final detection = environment.arguments.singleWhere(
            (args) => args.contains('detect-bundle-id'),
          );
          expect(detection[detection.indexOf('--config') + 1], expected);
        },
      );
    }

    for (final configurations in [
      ['Debug'],
      ['Release Dev One', 'Release Dev Two'],
    ]) {
      test(
        'stops before provisioning if no unique configuration matches: $configurations',
        () async {
          environment.flavor = 'dev';
          environment.configurations = configurations;

          await expectLater(environment.build(), throwsStateError);

          expect(
            environment.arguments.expand((args) => args),
            isNot(contains('app-store-connect')),
          );
        },
      );
    }

    for (final info in <Object>[
      {
        'workspace': {'name': 'Runner'},
      },
      {
        'project': {
          'name': 'Runner',
          'configurations': ['Release', 42],
        },
      },
    ]) {
      test('rejects malformed Xcode project metadata: $info', () async {
        environment.projectInfo = info;
        await expectLater(environment.build(), throwsFormatException);
        expect(environment.commands, hasLength(3));
      });
    }

    for (final bundleId in [
      '',
      r'$(PRODUCT_BUNDLE_IDENTIFIER)',
      'Unexpected log\norg.example.app',
    ]) {
      test('rejects an unresolved or invalid Bundle ID: $bundleId', () async {
        environment.bundleId = bundleId;
        await expectLater(environment.build(), throwsStateError);
        expect(environment.commands, hasLength(4));
      });
    }

    for (var failingStep = 0; failingStep < 10; failingStep++) {
      test('stops when step $failingStep fails', () async {
        final error = StateError('Build step failed');
        environment.beforeRun = (index) async {
          if (index == failingStep) throw error;
        };

        await expectLater(environment.build(), throwsA(same(error)));

        expect(environment.commands, hasLength(failingStep + 1));
      });
    }

    test(
      'waits for profile application before starting the IPA build',
      () async {
        final applying = Completer<void>();
        final applied = Completer<void>();
        environment.beforeRun = (index) async {
          if (index == 7) {
            applying.complete();
            await applied.future;
          }
        };

        final result = environment.build();
        await applying.future;
        expect(environment.commands, hasLength(8));
        applied.complete();
        await result;
        expect(environment.commands, hasLength(10));
      },
    );

    for (final artifact in ['missing', 'old', 'empty']) {
      test(
        'fails if Flutter returns success without a new IPA: $artifact',
        () async {
          environment.artifact = artifact;

          await expectLater(
            environment.build(),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                contains('Flutter did not export a new IPA.'),
              ),
            ),
          );
          expect(environment.commands, hasLength(10));
        },
      );
    }

    test('returns the new IPA when an older export is also present', () async {
      environment.artifact = 'old-and-new';

      final path = await environment.build();

      expect(path, endsWith('/app.ipa'));
      expect(await File(path).readAsString(), 'test IPA');
      expect(
        (await environment.temporary.list().toList()).where(
          (entry) => entry.path.contains('openci-ipa-build-'),
        ),
        isEmpty,
      );
    });

    test('supports an absolute Flutter build directory', () async {
      environment.buildDirectory = '${environment.workspace.path}/absolute out';

      final path = await environment.build();

      expect(path, '${environment.buildDirectory}/ios/ipa/app.ipa');
      expect(await File(path).readAsString(), 'test IPA');
    });

    test('rejects multiple new IPAs instead of choosing one', () async {
      environment.artifact = 'multiple';

      await expectLater(
        environment.build(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('multiple IPAs'),
          ),
        ),
      );
      expect(
        (await environment.temporary.list().toList()).where(
          (entry) => entry.path.contains('openci-ipa-build-'),
        ),
        isEmpty,
      );
    });

    for (final option in [
      '--export-method',
      '--export-method=app-store',
      '--export-options-plist',
      '--export-options-plist=custom.plist',
      '--no-codesign',
    ]) {
      test(
        'rejects managed signing options before running commands: $option',
        () async {
          await expectLater(
            environment.build(additionalArguments: [option]),
            throwsArgumentError,
          );
          expect(environment.commands, isEmpty);
          expect(await environment.temporary.list().toList(), isEmpty);
        },
      );
    }

    test('invalid ASC credentials stop before any build command', () async {
      await expectLater(
        environment.build(privateKeyBase64: 'invalid!!!'),
        throwsFormatException,
      );
      expect(environment.commands, isEmpty);
    });
  }, testOn: '!windows');
}

class _BuildEnvironment {
  _BuildEnvironment(this.workspace, this.temporary);

  final Directory workspace;
  final Directory temporary;
  final commands = <String>[];
  final workingDirectories = <String>[];
  final arguments = <List<String>>[];
  String? flavor;
  List<String> configurations = ['Debug', 'Release'];
  Object? projectInfo;
  String bundleId = 'org.example.app';
  String buildDirectory = 'build';
  String artifact = 'new';
  Future<void> Function(int index)? beforeRun;

  static Future<_BuildEnvironment> create() async {
    final workspace = await Directory.systemTemp.createTemp("openci ipa ' ");
    final temporary = Directory.fromUri(workspace.uri.resolve('temporary/'));
    await temporary.create();
    final bin = Directory.fromUri(workspace.uri.resolve('bin/'));
    await bin.create();
    for (final name in [
      'flutter',
      'xcodebuild',
      'xcode-project',
      'keychain',
      'app-store-connect',
    ]) {
      final executable = File.fromUri(bin.uri.resolve(name));
      await executable.writeAsString(r'''#!/bin/sh
set -eu
name=${0##*/}
printf '%s\000' "$name" "$@" > "$OPENCI_TEST_ARGUMENTS"
case "$name" in
  flutter)
    if [ "$2" = ios ]; then
      mkdir -p ios/Flutter
      cp "$OPENCI_TEST_SETTINGS" ios/Flutter/Generated.xcconfig
    elif [ "$2" = ipa ]; then
      case "$OPENCI_TEST_ARTIFACT" in
        new|old-and-new|multiple)
          mkdir -p "$OPENCI_TEST_IPA_DIR"
          printf 'test IPA' > "$OPENCI_TEST_IPA_DIR/app.ipa"
          if [ "$OPENCI_TEST_ARTIFACT" = multiple ]; then
            printf 'other IPA' > "$OPENCI_TEST_IPA_DIR/other.ipa"
          fi ;;
        empty) mkdir -p "$OPENCI_TEST_IPA_DIR"; touch "$OPENCI_TEST_IPA_DIR/app.ipa" ;;
      esac
    fi ;;
  xcodebuild) cat "$OPENCI_TEST_PROJECT_INFO" ;;
  xcode-project)
    if [ "$1" = detect-bundle-id ]; then
      printf 'Detection log\n' >&2
      printf '%s\n' "$OPENCI_TEST_BUNDLE_ID"
    fi ;;
esac
''');
      final result = await Process.run('chmod', ['700', executable.path]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
    }
    return _BuildEnvironment(workspace, temporary);
  }

  Future<String> build({
    IosDistributionMethod distributionMethod = IosDistributionMethod.adHoc,
    String? dir,
    String? flavor,
    List<String> additionalArguments = const [],
    String? privateKeyBase64,
  }) async {
    final workingApp = dir == ''
        ? workspace
        : Directory.fromUri(
            workspace.uri.resolve('${dir ?? 'apps/dashboard'}/'),
          );
    await Directory.fromUri(
      workingApp.uri.resolve('ios/Runner.xcodeproj/'),
    ).create(recursive: true);
    final settings = File.fromUri(workspace.uri.resolve('settings'));
    await settings.writeAsString(
      [
        'FLUTTER_BUILD_DIR=$buildDirectory',
        if (this.flavor != null) 'FLAVOR=${this.flavor}',
        'DART_DEFINES=do-not-copy-unrelated-settings',
        '',
      ].join('\n'),
    );
    final project = File.fromUri(workspace.uri.resolve('project.json'));
    await project.writeAsString(
      jsonEncode(
        projectInfo ??
            {
              'project': {'name': 'Runner', 'configurations': configurations},
            },
      ),
    );
    if (artifact == 'old' || artifact == 'old-and-new') {
      final filename = artifact == 'old' ? 'app.ipa' : 'old.ipa';
      final ipa = File.fromUri(
        workingApp.uri.resolve('$buildDirectory/ios/ipa/$filename'),
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
            'PATH': '${workspace.path}/bin:${Platform.environment['PATH']}',
            'OPENCI_TEST_ARGUMENTS': argumentsFile.path,
            'OPENCI_TEST_SETTINGS': settings.path,
            'OPENCI_TEST_PROJECT_INFO': project.path,
            'OPENCI_TEST_BUNDLE_ID': bundleId,
            'OPENCI_TEST_IPA_DIR': '$buildDirectory/ios/ipa',
            'OPENCI_TEST_ARTIFACT': artifact,
          },
        );
        if (await argumentsFile.exists()) {
          arguments.add(
            (await argumentsFile.readAsString()).split('\u0000')..removeLast(),
          );
        } else {
          arguments.add([]);
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
      () => ci.flutter.buildIpa(
        distributionMethod: distributionMethod,
        ascKeys: AppStoreConnectKeys(
          issuerId: 'test-issuer',
          keyId: 'TESTKEY',
          privateKeyBase64:
              privateKeyBase64 ?? base64Encode(utf8.encode('TEST_ASC_KEY')),
        ),
        certificatePrivateKey: 'TEST_CERTIFICATE_KEY',
        dir: dir,
        flavor: flavor,
        additionalArguments: additionalArguments,
      ),
      getSystemTempDirectory: () => temporary,
    );
  }
}
