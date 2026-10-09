import 'dart:async';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflow/src/ios_signing/initialize_ios_keychain.dart';
import 'package:test/test.dart';

void main() {
  group('initializeIosKeychain', () {
    test('waits for initialization to finish', () async {
      final initialized = Completer<void>();
      final commands = <String>[];
      var finished = false;

      final result = initializeIosKeychain(
        run: (command, {workingDirectory}) {
          commands.add(command);
          return initialized.future;
        },
      ).then((_) => finished = true);

      expect(commands, [
        'keychain initialize --path /tmp/openci-signing.keychain-db',
      ]);
      expect(finished, isFalse);

      initialized.complete();
      await result;
      expect(commands, hasLength(1));
      expect(finished, isTrue);
    });

    test('propagates initialization failures', () async {
      final error = StateError('Keychain command failed');
      var calls = 0;

      await expectLater(
        initializeIosKeychain(
          run: (_, {workingDirectory}) async {
            calls++;
            throw error;
          },
        ),
        throwsA(same(error)),
      );

      expect(calls, 1);
    });

    for (final dir in <String?>[null, 'apps/another app']) {
      test('uses the workflow runner and directory: $dir', () async {
        final calls = <(String, String)>[];
        final ci = OpenCI.forTesting(
          workspacePath: '/tmp/workspace',
          currentWorkingDirectory: 'apps/dashboard',
          commandRunner: (command, {required workingDirectory}) async {
            calls.add((command, workingDirectory));
          },
        );

        await initializeIosKeychain(
          run: ci.run,
          dir: dir,
        );

        final directory = '/tmp/workspace/${dir ?? 'apps/dashboard'}';
        expect(calls, [
          (
            'keychain initialize --path /tmp/openci-signing.keychain-db',
            directory,
          ),
        ]);
      });
    }
  });
}
