import 'dart:io';

import 'package:genuineci_cli/src/asc/start_asc_login.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _LoginProcess implements Process {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'starts the supplied asc path with inherited terminal handles',
    () async {
      final executable = File('cached tools/asc');
      final child = _LoginProcess();
      const appleId = "o'hara+ios@example.com";

      final process = await startAscLogin(
        executable,
        appleId,
        processStarter: (path, arguments, {required mode}) async {
          expect(path, executable.absolute.path);
          expect(arguments, [
            'web',
            'auth',
            'login',
            '--apple-id',
            appleId,
            '--output',
            'table',
          ]);
          expect(mode, ProcessStartMode.inheritStdio);
          return child;
        },
      );

      // The caller owns waiting; no captured stdin/stdout/stderr is accessed.
      expect(process, same(child));
    },
  );

  test('lets the caller handle a process startup failure', () async {
    final error = ProcessException('/cached/asc', [], 'permission denied');

    await expectLater(
      startAscLogin(
        File('/cached/asc'),
        'user@example.com',
        processStarter: (_, _, {required mode}) async => throw error,
      ),
      throwsA(same(error)),
    );
  });

  test(
    'runs a real executable with literal arguments and a usable exit code',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'genuineci asc login ',
      );
      addTearDown(() => root.delete(recursive: true));
      final executable = File(p.join(root.path, 'asc'));
      await executable.writeAsString('''#!/bin/sh
printf '%s\\n' "\$@" > "\$0.args"
exit 7
''');
      final chmod = await Process.run('/bin/chmod', ['700', executable.path]);
      expect(chmod.exitCode, 0);
      const appleId = "o'hara+ios@example.com";

      final child = await startAscLogin(executable, appleId);

      expect(await child.exitCode, 7);
      expect(await File('${executable.path}.args').readAsLines(), [
        'web',
        'auth',
        'login',
        '--apple-id',
        appleId,
        '--output',
        'table',
      ]);
    },
    skip: Platform.isWindows,
  );
}
