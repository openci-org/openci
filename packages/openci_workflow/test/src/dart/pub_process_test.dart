import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

void main() {
  Future<ProcessResult> run(String mode) async => Process.run(
    Platform.resolvedExecutable,
    [
      '--packages=${(await Isolate.packageConfig)!.toFilePath()}',
      'test/fixtures/run_pub_process.dart',
      mode,
    ],
  );

  test('redacts a token split across chunks on stdout and stderr', () async {
    final result = await run('logs');
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(result.stdout, contains('[REDACTED]'));
    expect(result.stderr, contains('[REDACTED]'));
    expect(
      '${result.stdout}${result.stderr}',
      isNot(contains('fake.identity.token')),
    );
    expect(result.stdout, contains('exit-code=7'));
  });

  test(
    'kills the timed-out process and reports uncertain publication',
    () async {
      final result = await run('timeout');
      expect(result.exitCode, 2, reason: '${result.stdout}${result.stderr}');
      expect(result.stderr, contains('check pub.dev before retrying'));
      final childPid = RegExp(
        r'child-pid=(\d+)',
      ).firstMatch(result.stdout as String);
      expect(childPid, isNotNull);
      expect(
        Process.killPid(int.parse(childPid!.group(1)!), ProcessSignal.sigcont),
        isFalse,
      );
    },
  );

  test(
    'reports a missing Dart executable without raw process details',
    () async {
      final result = await run('missing');
      expect(result.exitCode, 3);
      expect(result.stderr, contains('Make sure dart is on PATH'));
    },
  );
}
