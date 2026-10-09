import 'dart:async';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflow/src/ios_signing/apply_ios_provisioning_profiles.dart';
import 'package:test/test.dart';

void main() {
  group('applyIosProvisioningProfiles', () {
    test(
      'returns the export options path after profile application finishes',
      () async {
        final applied = Completer<void>();
        var calls = 0;
        var finished = false;

        final result =
            applyIosProvisioningProfiles(
              run: (_, {workingDirectory}) {
                calls++;
                return applied.future;
              },
              distributionMethod: IosDistributionMethod.adHoc,
            ).then((path) {
              finished = true;
              return path;
            });

        expect(calls, 1);
        expect(finished, isFalse);

        applied.complete();
        expect(await result, '/tmp/openci-export-options.plist');
        expect(finished, isTrue);
      },
    );

    test('propagates profile application failures', () async {
      final error = StateError('Could not apply provisioning profiles');
      var calls = 0;

      await expectLater(
        applyIosProvisioningProfiles(
          run: (_, {workingDirectory}) async {
            calls++;
            throw error;
          },
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

        await applyIosProvisioningProfiles(
          run: ci.run,
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

    test(
      'passes the iOS project glob and Ad Hoc export settings to the CLI',
      () async {
        final workspace = await Directory.systemTemp.createTemp(
          'openci apply profiles ',
        );
        addTearDown(() => workspace.delete(recursive: true));

        final binDirectory = Directory.fromUri(workspace.uri.resolve('bin/'));
        await binDirectory.create();
        final executable = File.fromUri(
          binDirectory.uri.resolve('xcode-project'),
        );
        await executable.writeAsString(r'''#!/bin/sh
printf '%s\000' "$@"
''');
        final chmod = await Process.run('chmod', ['700', executable.path]);
        expect(chmod.exitCode, 0, reason: chmod.stderr.toString());

        for (final path in [
          'app/ios/Runner.xcodeproj/',
          'app/ios/Another App.xcodeproj/',
          'app/ios/Pods/Pods.xcodeproj/',
          'app/macos/Runner.xcodeproj/',
        ]) {
          await Directory.fromUri(
            workspace.uri.resolve(path),
          ).create(recursive: true);
        }

        late List<String> arguments;
        final ci = OpenCI.forTesting(
          workspacePath: workspace.path,
          currentWorkingDirectory: 'app',
          commandRunner: (command, {required workingDirectory}) async {
            final result = await Process.run(
              '/bin/sh',
              ['-c', command],
              workingDirectory: workingDirectory,
              environment: {
                'PATH': '${binDirectory.path}:${Platform.environment['PATH']}',
              },
            );

            expect(result.exitCode, 0, reason: result.stderr.toString());
            arguments = (result.stdout as String).split('\u0000');
          },
        );

        final exportOptionsPath = await applyIosProvisioningProfiles(
          run: ci.run,
          distributionMethod: IosDistributionMethod.adHoc,
        );

        expect(arguments, [
          'use-profiles',
          '--project',
          'ios/*.xcodeproj',
          '--archive-method',
          'ad-hoc',
          '--export-options-plist',
          exportOptionsPath,
          '',
        ]);
      },
      testOn: '!windows',
    );
  });
}
