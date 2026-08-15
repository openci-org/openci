import 'dart:io';

import 'package:meta/meta.dart';

import 'ci_trigger.dart';
import 'command_runner.dart';
import 'machine_type.dart';

class GenuineCI {
  GenuineCI._({
    required this.workflowName,
    required this.ciTrigger,
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
       ciTrigger = const CiTrigger.push(branch: 'test'),
       machine = MachineType.macOsLatest,
       githubRepositoryUrl = 'https://example.com/test.git';

  final String workflowName;
  final CiTrigger ciTrigger;
  final MachineType machine;
  final String? currentWorkingDirectory;
  final String githubRepositoryUrl;
  final String workspacePath;

  static Future<GenuineCI> init({
    required String workflowName,
    required CiTrigger ciTrigger,
    MachineType machine = MachineType.macOsLatest,
    String? currentWorkingDirectory,
    required String githubRepositoryUrl,
    bool gitClone = true,
  }) async {
    final workspacePath = await createWorkspace();

    final instance = GenuineCI._(
      workflowName: workflowName,
      ciTrigger: ciTrigger,
      machine: machine,
      currentWorkingDirectory: currentWorkingDirectory,
      githubRepositoryUrl: githubRepositoryUrl,
      workspacePath: workspacePath,
    );
    if (gitClone) {
      await instance._cloneRepository();
    }

    return instance;
  }

  Future<void> _cloneRepository() async {
    const space = ' ';
    final command = [
      'git clone',
      '--branch ${ciTrigger.branch}',
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
