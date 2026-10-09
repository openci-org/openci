import 'dart:async';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflow/src/ios_signing/import_ios_signing_certificates.dart';
import 'package:openci_workflow/src/ios_signing/initialize_ios_keychain.dart';
import 'package:test/test.dart';

void main() {
  group('importIosSigningCertificates', () {
    test(
      'imports into the initialized keychain and waits for completion',
      () async {
        final imported = Completer<void>();
        final commands = <String>[];
        var finished = false;

        await initializeIosKeychain(
          run: (command, {workingDirectory}) async {
            commands.add(command);
          },
        );
        final result = importIosSigningCertificates(
          run: (command, {workingDirectory}) {
            commands.add(command);
            return imported.future;
          },
        ).then((_) => finished = true);

        expect(commands, [
          'keychain initialize --path /tmp/openci-signing.keychain-db',
          'keychain add-certificates --path /tmp/openci-signing.keychain-db',
        ]);
        expect(finished, isFalse);

        imported.complete();
        await result;
        expect(finished, isTrue);
      },
    );

    test('propagates import failures', () async {
      final error = StateError('Could not import signing certificates');
      var calls = 0;

      await expectLater(
        importIosSigningCertificates(
          run: (_, {workingDirectory}) async {
            calls++;
            throw error;
          },
        ),
        throwsA(same(error)),
      );

      expect(calls, 1);
    });

    for (final dir in <String?>[null, '', 'apps/another app']) {
      test('uses the workflow runner and directory: $dir', () async {
        final calls = <(String, String)>[];
        final ci = OpenCI.forTesting(
          workspacePath: '/tmp/workspace',
          currentWorkingDirectory: 'apps/dashboard',
          commandRunner: (command, {required workingDirectory}) async {
            calls.add((command, workingDirectory));
          },
        );

        await importIosSigningCertificates(run: ci.run, dir: dir);

        final directory = dir == ''
            ? '/tmp/workspace'
            : '/tmp/workspace/${dir ?? 'apps/dashboard'}';
        expect(calls, [
          (
            'keychain add-certificates --path /tmp/openci-signing.keychain-db',
            directory,
          ),
        ]);
      });
    }
  });
}
