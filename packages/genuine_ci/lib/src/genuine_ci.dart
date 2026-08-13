import 'dart:io';

import 'package:meta/meta.dart';

import 'command_runner.dart';

class GenuineCI {
  GenuineCI._({
    required this.workflowName,
    required this.triggerBranch,
    required this.push,
    required this.pullRequest,
    required this.machine,
    this.currentWorkingDirectory,
    required this.githubRepositoryUrl,
    required this.workspacePath,
  });

  @visibleForTesting
  GenuineCI.forTesting({
    required this.workspacePath,
    this.currentWorkingDirectory,
  }) : workflowName = 'test',
       triggerBranch = 'test',
       push = false,
       pullRequest = false,
       machine = 'test',
       githubRepositoryUrl = 'https://example.com/test.git';

  final String workflowName;
  final String triggerBranch;
  final bool push;
  final bool pullRequest;
  final String machine;
  final String? currentWorkingDirectory;
  final String githubRepositoryUrl;
  final String workspacePath;

  static Future<GenuineCI> init({
    required String workflowName,
    required String triggerBranch,
    required bool push,
    required bool pullRequest,
    required String machine,
    String? currentWorkingDirectory,
    required String githubRepositoryUrl,
  }) async {
    final workspacePath = await createWorkspace();

    final instance = GenuineCI._(
      workflowName: workflowName,
      triggerBranch: triggerBranch,
      push: push,
      pullRequest: pullRequest,
      machine: machine,
      currentWorkingDirectory: currentWorkingDirectory,
      githubRepositoryUrl: githubRepositoryUrl,
      workspacePath: workspacePath,
    );

    await instance._cloneRepository();

    return instance;
  }

  Future<void> _cloneRepository() async {
    const space = ' ';
    final command = [
      'git clone',
      '--branch $triggerBranch',
      '--single-branch',
      '--progress',
      githubRepositoryUrl,
      '.',
    ].join(space);

    await runCommand(
      command,
      workingDirectory: workspacePath,
    );
  }

  Future<void> run(
    String command, {
    String? workingDirectory,
  }) async {
    final cwd = resolveWorkingDirectory(
      workingDirectory ?? currentWorkingDirectory,
    );
    await runCommand(command, workingDirectory: cwd);
  }

  @visibleForTesting
  static Future<String> createWorkspace() async {
    const dirPrefix = 'genuine_ci_';
    final directory = await Directory.systemTemp.createTemp(dirPrefix);
    return directory.path;
  }

  @visibleForTesting
  String resolveWorkingDirectory([String? relativeCwd]) {
    if (relativeCwd == null || relativeCwd.isEmpty) return workspacePath;
    return '$workspacePath${Platform.pathSeparator}$relativeCwd';
  }
}
