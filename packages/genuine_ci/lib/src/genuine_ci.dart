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
    required this.workspacePath,
  });

  @visibleForTesting
  GenuineCI.forTesting({
    required this.workspacePath,
    this.currentWorkingDirectory,
  }) : workflowName = 'test',
       ciTrigger = const CiTrigger.push(branch: 'test'),
       machine = MachineType.macOsLatest;

  final String workflowName;
  final CiTrigger ciTrigger;
  final MachineType machine;
  final String? currentWorkingDirectory;
  final String workspacePath;

  static Future<GenuineCI> init({
    required String workflowName,
    required CiTrigger ciTrigger,
    MachineType machine = MachineType.macOsLatest,
    String? currentWorkingDirectory,
    String? workspacePath,
  }) async {
    final workspace = workspacePath ?? Directory.current.path;

    return GenuineCI._(
      workflowName: workflowName,
      ciTrigger: ciTrigger,
      machine: machine,
      currentWorkingDirectory: currentWorkingDirectory,
      workspacePath: workspace,
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
  String resolveWorkingDirectory([String? relativeCwd]) {
    if (relativeCwd == null || relativeCwd.isEmpty) return workspacePath;
    return '$workspacePath${Platform.pathSeparator}$relativeCwd';
  }
}
