import 'dart:io';

class SSHResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  SSHResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

class SSHExec {
  final String host;
  final String user;
  final String password;

  SSHExec({required this.host, required this.user, required this.password});

  Future<SSHResult> run(String command, {int timeoutSeconds = 60}) async {
    final result =
        await Process.run('sshpass', [
          '-p',
          password,
          'ssh',
          '-o',
          'StrictHostKeyChecking=no',
          '-o',
          'IdentitiesOnly=yes',
          '-o',
          'ConnectTimeout=5',
          '-i',
          '/dev/null',
          '$user@$host',
          command,
        ]).timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () => ProcessResult(-1, 124, '', 'Command timed out'),
        );

    return SSHResult(
      exitCode: result.exitCode,
      stdout: (result.stdout as String).trimRight(),
      stderr: (result.stderr as String).trimRight(),
    );
  }

  Future<void> waitForReady({int maxAttempts = 30}) async {
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final result = await run('echo ok', timeoutSeconds: 10);
        if (result.exitCode == 0 && result.stdout.contains('ok')) return;
      } catch (_) {}
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw Exception('SSH not ready after $maxAttempts attempts');
  }
}
