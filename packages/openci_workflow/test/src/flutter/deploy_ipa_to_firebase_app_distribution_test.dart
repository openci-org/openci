import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

const _appId = '1:123456789:ios:abcdef';
const _credentials = {
  'type': 'service_account',
  'project_id': 'test-project',
  'client_email': 'test@test-project.iam.gserviceaccount.com',
  'private_key': 'TEST_PRIVATE_KEY_DO_NOT_LOG',
};
final _credentialsBase64 = base64Encode(utf8.encode(jsonEncode(_credentials)));

void main() {
  group('deployIpaToFirebaseAppDistribution', () {
    late _UploadEnvironment environment;

    setUp(() async => environment = await _UploadEnvironment.create());
    tearDown(() => environment.workspace.delete(recursive: true));

    for (final binary in [false, true]) {
      test('reads the exported Firebase config (binary: $binary)', () async {
        await environment.createIpa(
          binary: binary,
          configs: {
            "Payload/Runner's [prod].app/GoogleService-Info.plist": _plist(
              _appId,
            ),
            'Payload/Runner.app/Watch/Watch.app/GoogleService-Info.plist':
                _plist('1:987654321:ios:123abc'),
          },
        );

        await environment.deploy();

        expect(await environment.uploadArguments(), [
          'appdistribution:distribute',
          './app.ipa',
          '--app',
          _appId,
          '--non-interactive',
        ]);
        expect(environment.workingDirectories.toSet(), {
          environment.appDirectory(null).path,
        });
        expect(
          jsonDecode(
            await environment.file('uploaded-credentials').readAsString(),
          ),
          _credentials,
        );
        expect(
          (await environment.file('credential-mode').readAsString()).trim(),
          '600',
        );
        final auth = (await environment.file('auth-environment').readAsString())
            .split('\u0000');
        expect(
          auth[2],
          isEmpty,
          reason: 'Inherited FIREBASE_TOKEN is cleared.',
        );
        expect(await File(auth[0]).exists(), isFalse);
        expect(await Directory(auth[1]).exists(), isFalse);
        expect(await environment.temporary.list().toList(), isEmpty);
        expect(
          environment.commands.join('\n'),
          isNot(contains(_credentialsBase64)),
        );
        expect(
          environment.commands.join('\n'),
          isNot(contains(_credentials['private_key']!)),
        );
      });
    }

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test('resolves the IPA in the workflow directory: $dir', () async {
        await environment.createIpa(dir: dir);

        await environment.deploy(dir: dir);

        expect(environment.workingDirectories.toSet(), {
          environment.appDirectory(dir).path,
        });
      });
    }

    test('accepts an absolute IPA path from another directory', () async {
      final ipa = await environment.createIpa();

      await environment.deploy(ipaPath: ipa.path, dir: '');

      expect((await environment.uploadArguments())[1], ipa.path);
    });

    test('uses a custom CLI path as a literal argument', () async {
      await environment.createIpa();
      const executablePath = r"tools/firebase ' $(touch unexpected)";
      final executable = File(
        '${environment.appDirectory(null).path}/$executablePath',
      );
      await executable.parent.create();
      await environment.file('bin/firebase').rename(executable.path);

      await environment.deploy(firebaseCliPath: executablePath);

      expect(await environment.uploadArguments(), contains(_appId));
      expect(
        await File(
          '${environment.appDirectory(null).path}/unexpected',
        ).exists(),
        isFalse,
      );
    });

    test('rejects an empty CLI path before running commands', () async {
      await expectLater(
        environment.deploy(firebaseCliPath: '  '),
        throwsArgumentError,
      );

      expect(environment.commands, isEmpty);
    });

    test(
      'uses an explicit App ID without requiring a bundled config',
      () async {
        await environment.createIpa(configs: {});

        await environment.deploy(appId: _appId);

        expect(environment.commands, hasLength(1));
        expect(await environment.uploadArguments(), contains(_appId));
      },
    );

    test(
      'passes paths, groups, testers, and notes as literal arguments',
      () async {
        const notes =
            r'''--notes=' "$SECRET" `printf expanded` $(printf expanded)
second line''';
        const filename = r'''-app ' $(printf expanded).ipa''';
        await environment.createIpa(filename: filename);

        await environment.deploy(
          ipaPath: filename,
          groups: ['qa-team', 'internal'],
          testers: ["o'connor@example.com", 'test@example.com'],
          releaseNotes: notes,
        );

        expect(await environment.uploadArguments(), [
          'appdistribution:distribute',
          './$filename',
          '--app',
          _appId,
          '--non-interactive',
          '--groups=qa-team,internal',
          "--testers=o'connor@example.com,test@example.com",
          '--release-notes=$notes',
        ]);
      },
    );

    test(
      'preserves a failed upload status and removes credentials in the shell',
      () async {
        await environment.createIpa();
        environment.firebaseExitCode = 17;
        environment.checkShellCleanup = true;

        await expectLater(
          environment.deploy(),
          throwsA(
            isA<ProcessException>().having(
              (error) => error.errorCode,
              'exit',
              17,
            ),
          ),
        );

        expect(await environment.temporary.list().toList(), isEmpty);
      },
    );

    test('removes credentials when the command runner cannot start', () async {
      await environment.createIpa();
      environment.failUploadStart = true;

      await expectLater(environment.deploy(), throwsStateError);

      expect(await environment.temporary.list().toList(), isEmpty);
    });

    for (final configs in [
      <String, String>{},
      {
        'Payload/Runner.app/GoogleService-Info.plist': _plist(_appId),
        'Payload/Other.app/GoogleService-Info.plist': _plist(_appId),
      },
    ]) {
      test(
        'rejects missing or ambiguous app config: ${configs.length}',
        () async {
          await environment.createIpa(configs: configs);

          await expectLater(environment.deploy(), throwsStateError);

          expect(await environment.file('arguments').exists(), isFalse);
          expect(await environment.temporary.list().toList(), isEmpty);
        },
      );
    }

    for (final plist in [
      'not a plist',
      '<plist><dict><key>OTHER</key><string>value</string></dict></plist>',
      '<plist><dict><key>GOOGLE_APP_ID</key><integer>42</integer></dict></plist>',
    ]) {
      test('rejects invalid or missing GOOGLE_APP_ID: $plist', () async {
        await environment.createIpa(
          configs: {'Payload/Runner.app/GoogleService-Info.plist': plist},
        );

        await expectLater(
          environment.deploy(),
          throwsA(isA<ProcessException>()),
        );

        expect(await environment.file('arguments').exists(), isFalse);
        expect(await environment.temporary.list().toList(), isEmpty);
      });
    }

    test('does not upload an unreadable IPA', () async {
      await File(
        '${environment.appDirectory(null).path}/app.ipa',
      ).writeAsString('not a zip');

      await expectLater(environment.deploy(), throwsA(isA<ProcessException>()));

      expect(await environment.file('arguments').exists(), isFalse);
      expect(await environment.temporary.list().toList(), isEmpty);
    });

    for (final appId in ['', 'org.example.app', '1:123:android:abcdef']) {
      test('rejects an invalid Firebase iOS App ID: $appId', () async {
        await expectLater(
          environment.deploy(appId: appId),
          throwsArgumentError,
        );
        expect(environment.commands, isEmpty);
        expect(await environment.temporary.list().toList(), isEmpty);
      });
    }

    for (final secret in [
      'invalid-base64-TEST_PRIVATE_KEY_DO_NOT_LOG!',
      base64Encode(utf8.encode('invalid-json-TEST_PRIVATE_KEY_DO_NOT_LOG')),
      base64Encode(utf8.encode('[]')),
      base64Encode(utf8.encode('{"type":"authorized_user"}')),
      base64Encode(utf8.encode('{"type":"service_account"}')),
    ]) {
      test(
        'rejects malformed credentials without exposing their contents',
        () async {
          await expectLater(
            environment.deploy(serviceAccountJsonBase64: secret),
            throwsA(
              isA<FormatException>()
                  .having((error) => error.source, 'source', isNull)
                  .having(
                    (error) => error.toString(),
                    'message',
                    isNot(contains('TEST_PRIVATE_KEY_DO_NOT_LOG')),
                  ),
            ),
          );
          expect(environment.commands, isEmpty);
          expect(await environment.temporary.list().toList(), isEmpty);
        },
      );
    }
  }, testOn: 'mac-os');
}

String _plist(String appId) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>GOOGLE_APP_ID</key><string>$appId</string></dict></plist>
''';

class _UploadEnvironment {
  _UploadEnvironment(this.workspace, this.temporary);

  final Directory workspace;
  final Directory temporary;
  final commands = <String>[];
  final workingDirectories = <String>[];
  int firebaseExitCode = 0;
  bool failUploadStart = false;
  bool checkShellCleanup = false;

  File file(String name) => File.fromUri(workspace.uri.resolve(name));

  Directory appDirectory(String? dir) => dir == ''
      ? workspace
      : Directory('${workspace.path}/${dir ?? 'apps/dashboard'}');

  static Future<_UploadEnvironment> create() async {
    final workspace = await Directory.systemTemp.createTemp("openci fad ' ");
    final temporary = Directory.fromUri(workspace.uri.resolve('temporary/'));
    await temporary.create();
    final environment = _UploadEnvironment(workspace, temporary);
    await environment.appDirectory(null).create(recursive: true);
    final executable = environment.file('bin/firebase');
    await executable.parent.create();
    await executable.writeAsString(r'''#!/bin/sh
set -eu
printf '%s\000' "$@" > "$OPENCI_TEST_OUTPUT/arguments"
printf '%s\000' "$GOOGLE_APPLICATION_CREDENTIALS" "$XDG_CONFIG_HOME" "$FIREBASE_TOKEN" > "$OPENCI_TEST_OUTPUT/auth-environment"
stat -f '%Lp' "$GOOGLE_APPLICATION_CREDENTIALS" > "$OPENCI_TEST_OUTPUT/credential-mode"
cat "$GOOGLE_APPLICATION_CREDENTIALS" > "$OPENCI_TEST_OUTPUT/uploaded-credentials"
exit "$OPENCI_TEST_EXIT_CODE"
''');
    final result = await Process.run('chmod', ['700', executable.path]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    return environment;
  }

  Future<File> createIpa({
    String filename = 'app.ipa',
    String? dir,
    bool binary = false,
    Map<String, String>? configs,
  }) async {
    final directory = appDirectory(dir);
    await directory.create(recursive: true);
    final payload = Directory.fromUri(directory.uri.resolve('Payload/'));
    await payload.create();
    await File.fromUri(payload.uri.resolve('README')).writeAsString('Test IPA');
    for (final config
        in (configs ??
                {
                  'Payload/Runner.app/GoogleService-Info.plist': _plist(_appId),
                })
            .entries) {
      final plist = File.fromUri(directory.uri.resolve(config.key));
      await plist.parent.create(recursive: true);
      await plist.writeAsString(config.value);
      if (binary) {
        final result = await Process.run('plutil', [
          '-convert',
          'binary1',
          plist.path,
        ]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
      }
    }
    final ipa = File('${directory.path}/$filename');
    final result = await Process.run('zip', [
      '-q',
      '-r',
      ipa.path,
      'Payload',
    ], workingDirectory: directory.path);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    return ipa;
  }

  Future<List<String>> uploadArguments() async =>
      (await file('arguments').readAsString()).split('\u0000')..removeLast();

  Future<void> deploy({
    String ipaPath = 'app.ipa',
    String? serviceAccountJsonBase64,
    String firebaseCliPath = 'firebase',
    String? appId,
    List<String> groups = const [],
    List<String> testers = const [],
    String? releaseNotes,
    String? dir,
  }) async {
    final ci = OpenCI.forTesting(
      workspacePath: workspace.path,
      currentWorkingDirectory: 'apps/dashboard',
      commandRunner: (command, {required workingDirectory}) async {
        commands.add(command);
        workingDirectories.add(workingDirectory);
        final isUpload = command.contains(
          'appdistribution:distribute',
        );
        if (isUpload && failUploadStart) {
          throw StateError('Could not start shell');
        }
        final result = await Process.run(
          '/bin/sh',
          ['-c', command],
          workingDirectory: workingDirectory,
          environment: {
            'PATH': '${workspace.path}/bin:${Platform.environment['PATH']}',
            'OPENCI_TEST_OUTPUT': workspace.path,
            'OPENCI_TEST_EXIT_CODE': '$firebaseExitCode',
            'FIREBASE_TOKEN': 'inherited-token',
          },
        );
        if (isUpload && checkShellCleanup) {
          // Assert before the helper's Dart finally can run.
          expect(await temporary.list().toList(), isEmpty);
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
    await IOOverrides.runZoned(
      () => ci.flutter.deployIpaToFirebaseAppDistribution(
        ipaPath: ipaPath,
        serviceAccountJsonBase64:
            serviceAccountJsonBase64 ?? _credentialsBase64,
        firebaseCliPath: firebaseCliPath,
        appId: appId,
        groups: groups,
        testers: testers,
        releaseNotes: releaseNotes,
        dir: dir,
      ),
      getSystemTempDirectory: () => temporary,
    );
  }
}
