import 'dart:io';

class SSHClient {
  final String host;
  final String user;
  final String password;

  SSHClient({required this.host, required this.user, required this.password});

  Future<SSHResult> exec(String command, {int timeoutSeconds = 30}) async {
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

  Future<bool> isReachable() async {
    try {
      final result = await exec('echo ok', timeoutSeconds: 10);
      return result.exitCode == 0 && result.stdout.contains('ok');
    } catch (_) {
      return false;
    }
  }
}

class SSHResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  SSHResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  Map<String, dynamic> toJson() => {
    'exit_code': exitCode,
    'stdout': stdout,
    'stderr': stderr,
  };
}
