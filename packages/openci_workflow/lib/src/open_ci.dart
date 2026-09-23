import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import 'ci_trigger.dart';
import 'command_runner.dart';
import 'flutter/flutter_ci.dart';
import 'machine_type.dart';
import 'workspace_directory.dart';

class OpenCI {
  OpenCI._({
    required this.workflowName,
    required this.ciTriggers,
    required this.machine,
    this.currentWorkingDirectory,
    required this.workspacePath,
  }) : _runCommand = runCommand;

  @visibleForTesting
  OpenCI.forTesting({
    required this.workspacePath,
    this.currentWorkingDirectory,
    Future<void> Function(String command, {required String workingDirectory})
        commandRunner =
        runCommand,
  }) : _runCommand = commandRunner,
       workflowName = 'test',
       ciTriggers = const [CITrigger.push(branch: 'test')],
       machine = MachineType.macOsLatest;

  final String workflowName;

  /// Events that can start this workflow. Any matching trigger schedules a run.
  final List<CITrigger> ciTriggers;
  final MachineType machine;
  final String? currentWorkingDirectory;
  final String workspacePath;

  final Future<void> Function(
    String command, {
    required String workingDirectory,
  })
  _runCommand;

  late final FlutterCI flutter = FlutterCI(run);

  static Future<OpenCI> init({
    required String workflowName,
    required List<CITrigger> ciTriggers,
    MachineType machine = MachineType.macOsLatest,
    String? currentWorkingDirectory,
    String? workspacePath,
  }) async {
    final workspace = workspacePath ?? Directory.current.path;

    return OpenCI._(
      workflowName: workflowName,
      ciTriggers: List.unmodifiable(ciTriggers),
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
    await _runCommand(command, workingDirectory: cwd);
  }

  Future<void> placeFileFromBase64({
    required WorkspaceDirectory dir,
    required String fileName,
    required String base64Content,
  }) async {
    final List<int> bytes;
    try {
      bytes = base64Decode(base64Content);
    } on FormatException {
      throw const FormatException('Invalid Base64 content.');
    }
    final file = File(
      '${resolveWorkingDirectory(dir)}${Platform.pathSeparator}$fileName',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @visibleForTesting
  String resolveWorkingDirectory([String? relativeCwd]) {
    if (relativeCwd == null || relativeCwd.isEmpty) return workspacePath;
    return '$workspacePath${Platform.pathSeparator}$relativeCwd';
  }
}
