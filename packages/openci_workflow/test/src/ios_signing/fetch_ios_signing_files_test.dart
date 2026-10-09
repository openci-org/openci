import 'dart:async';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflow/src/ios_signing/fetch_ios_signing_files.dart';
import 'package:openci_workflow/src/ios_signing/ios_signing_credentials.dart';
import 'package:test/test.dart';

void main() {
  const credentials = IosSigningCredentials(
    issuerId: 'test-issuer-id',
    keyId: 'TESTKEYID',
    ascPrivateKeyPath: '/tmp/openci-ios-signing/asc-private-key.p8',
    certificatePrivateKeyPath:
        '/tmp/openci-ios-signing/certificate-private-key.pem',
  );
  const bundleId = 'org.openci.dashboard.prod';

  group('fetchIosSigningFiles', () {
    test('waits for signing files to be fetched', () async {
      final fetched = Completer<void>();
      var calls = 0;
      var finished = false;

      final result = fetchIosSigningFiles(
        run: (_, {workingDirectory}) {
          calls++;
          return fetched.future;
        },
        credentials: credentials,
        bundleId: bundleId,
        distributionMethod: IosDistributionMethod.adHoc,
      ).then((_) => finished = true);

      expect(calls, 1);
      expect(finished, isFalse);

      fetched.complete();
      await result;
      expect(finished, isTrue);
    });

    test('propagates fetch failures', () async {
      final error = StateError('Could not fetch signing files');
      var calls = 0;

      await expectLater(
        fetchIosSigningFiles(
          run: (_, {workingDirectory}) async {
            calls++;
            throw error;
          },
          credentials: credentials,
          bundleId: bundleId,
          distributionMethod: IosDistributionMethod.adHoc,
        ),
        throwsA(same(error)),
      );

      expect(calls, 1);
    });

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test('uses the workflow runner and directory: $dir', () async {
        final directories = <String>[];
        final ci = OpenCI.forTesting(
          workspacePath: '/tmp/workspace',
          currentWorkingDirectory: 'apps/dashboard',
          commandRunner: (_, {required workingDirectory}) async {
            directories.add(workingDirectory);
          },
        );

        await fetchIosSigningFiles(
          run: ci.run,
          credentials: credentials,
          bundleId: bundleId,
          distributionMethod: IosDistributionMethod.adHoc,
          dir: dir,
        );

        expect(directories, [
          if (dir == '')
            '/tmp/workspace'
          else
            '/tmp/workspace/${dir ?? 'apps/dashboard'}',
        ]);
      });
    }

    group('command arguments', () {
      late Directory binDirectory;

      setUp(() async {
        binDirectory = await Directory.systemTemp.createTemp(
          'openci fetch signing files ',
        );
        final executable = File.fromUri(
          binDirectory.uri.resolve('app-store-connect'),
        );
        await executable.writeAsString(r'''#!/bin/sh
printf '%s\000' "$@"
''');
        final result = await Process.run('chmod', ['700', executable.path]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
      });

      tearDown(() => binDirectory.delete(recursive: true));

      for (final specialCharacters in [false, true]) {
        test(
          'fetches or creates Ad Hoc files with literal arguments: $specialCharacters',
          () async {
            final suffix = specialCharacters
                ? r''' ' "$OPENCI_TEST_VALUE" `printf expanded` $(printf expanded); printf injected'''
                : '';
            final input = IosSigningCredentials(
              issuerId: '${credentials.issuerId}$suffix',
              keyId: '${credentials.keyId}$suffix',
              ascPrivateKeyPath: '${credentials.ascPrivateKeyPath}$suffix',
              certificatePrivateKeyPath:
                  '${credentials.certificatePrivateKeyPath}$suffix',
            );
            final identifier = '$bundleId$suffix';

            await fetchIosSigningFiles(
              run: (command, {workingDirectory}) async {
                final result = await Process.run(
                  '/bin/sh',
                  ['-c', command],
                  environment: {
                    'PATH':
                        '${binDirectory.path}:${Platform.environment['PATH']}',
                    'OPENCI_TEST_VALUE': 'expanded',
                  },
                );

                expect(result.exitCode, 0, reason: result.stderr.toString());
                expect((result.stdout as String).split('\u0000'), [
                  'fetch-signing-files',
                  identifier,
                  '--issuer-id',
                  input.issuerId,
                  '--key-id',
                  input.keyId,
                  '--private-key',
                  '@file:${input.ascPrivateKeyPath}',
                  '--certificate-key',
                  '@file:${input.certificatePrivateKeyPath}',
                  '--type',
                  'IOS_APP_ADHOC',
                  '--create',
                  '',
                ]);
              },
              credentials: input,
              bundleId: identifier,
              distributionMethod: IosDistributionMethod.adHoc,
            );
          },
        );
      }
    }, testOn: '!windows');
  });
}
