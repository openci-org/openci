import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final genuineCI = await GenuineCI.init(
    workflowName: 'Dashboard CI',
    triggerBranch: 'develop',
    push: true,
    pullRequest: true,
    machine: 'macos-latest',
    githubRepositoryUrl: 'https://github.com/openci-org/openci.git',
  );

  await genuineCI.run('pwd');
  await genuineCI.run('git log -1 --oneline');
  await genuineCI.run('ls', workingDirectory: 'apps/dashboard');
}

class GenuineCI {
  GenuineCI._({
    required this.workflowName,
    required this.triggerBranch,
    required this.push,
    required this.pullRequest,
    required this.machine,
    this.currentWorkingDirectory,
    required this.githubRepositoryUrl,
    required this.workspaceDirectory,
  });

  final String workflowName;
  final String triggerBranch;
  final bool push;
  final bool pullRequest;
  final String machine;
  final String? currentWorkingDirectory;
  final String githubRepositoryUrl;
  final String workspaceDirectory;

  static Future<GenuineCI> init({
    required String workflowName,
    required String triggerBranch,
    required bool push,
    required bool pullRequest,
    required String machine,
    String? currentWorkingDirectory,
    required String githubRepositoryUrl,
  }) async {
    final workspaceDirectory = (await Directory.systemTemp.createTemp(
      'genuine_ci_',
    )).path;
    final instance = GenuineCI._(
      workflowName: workflowName,
      triggerBranch: triggerBranch,
      push: push,
      pullRequest: pullRequest,
      machine: machine,
      currentWorkingDirectory: currentWorkingDirectory,
      githubRepositoryUrl: githubRepositoryUrl,
      workspaceDirectory: workspaceDirectory,
    );

    await instance._gitClone();

    return instance;
  }

  Future<void> _gitClone() async {
    stdout.writeln('[INFO] workspace: $workspaceDirectory');
    await run(
      'git clone --branch $triggerBranch --single-branch --progress $githubRepositoryUrl .',
      workingDirectory: workspaceDirectory,
    );
  }

  Future<void> run(
    String command, {
    String? workingDirectory,
  }) async {
    final process = await Process.start(
      'sh',
      ['-c', command],
      workingDirectory: workingDirectory ?? _commandWorkingDirectory,
    );

    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .map((chunk) => chunk.replaceAll('\r', '\n'))
        .transform(const LineSplitter())
        .forEach((line) {
          stdout.writeln('[STDOUT] $line');
        });

    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .map((chunk) => chunk.replaceAll('\r', '\n'))
        .transform(const LineSplitter())
        .forEach((line) {
          stderr.writeln('[STDERR] $line');
        });

    await Future.wait([stdoutDone, stderrDone]);

    final exitCode = await process.exitCode;

    if (exitCode == 0) {
      stdout.writeln('[OK] command "$command" executed successfully');
      return;
    }
    stderr.writeln(
      '[ERROR] command "$command" failed with exit code $exitCode',
    );
    exit(exitCode);
  }

  String get _commandWorkingDirectory {
    final cwd = currentWorkingDirectory;
    if (cwd == null || cwd.isEmpty) return workspaceDirectory;
    return '$workspaceDirectory${Platform.pathSeparator}$cwd';
  }
}
