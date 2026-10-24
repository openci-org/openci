import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import 'ci_trigger.dart';
import 'command_runner.dart';
import 'flutter/flutter_ci.dart';
import 'go/go_ci.dart';
import 'machine_type.dart';
import 'shorebird/shorebird_ci.dart';
import 'workspace_directory.dart';

class OpenCI {
  OpenCI({
    required this.workflowName,
    required List<CITrigger> ciTriggers,
    this.machine = MachineType.macOsLatest,
    this.currentWorkingDirectory,
    required this.workspacePath,
    @visibleForTesting
    Future<void> Function(String command, {required String workingDirectory})
        commandRunner =
        runCommand,
  }) : ciTriggers = List.unmodifiable(ciTriggers),
       _runCommand = commandRunner;

  final String workflowName;

  /// Events that can start this workflow. Any matching trigger schedules a run.
  final List<CITrigger> ciTriggers;
  final MachineType machine;
  final String? currentWorkingDirectory;
  final String workspacePath;

  /// The team-scoped number assigned to this run by the server.
  ///
  /// Reads `OPENCI_RUN_NUMBER` without allocating a number or making a request.
  /// Throws a [StateError] if the variable is missing or is not a positive
  /// decimal integer. Set it explicitly when running a workflow locally.
  int get runNumber {
    final value = Platform.environment['OPENCI_RUN_NUMBER'];
    final number = value == null ? null : int.tryParse(value, radix: 10);
    if (number == null || number <= 0) {
      throw StateError(
        'OPENCI_RUN_NUMBER must be set to a positive decimal integer.',
      );
    }
    return number;
  }

  final Future<void> Function(
    String command, {
    required String workingDirectory,
  })
  _runCommand;

  late final FlutterCI flutter = FlutterCI(run);

  late final GoCI go = GoCI(run);

  late final ShorebirdCI shorebird = ShorebirdCI(run);

  static Future<OpenCI> init({
    required String workflowName,
    required List<CITrigger> ciTriggers,
    MachineType machine = MachineType.macOsLatest,
    String? currentWorkingDirectory,
    String? workspacePath,
  }) async {
    final workspace = workspacePath ?? Directory.current.path;

    return OpenCI(
      workflowName: workflowName,
      ciTriggers: ciTriggers,
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
