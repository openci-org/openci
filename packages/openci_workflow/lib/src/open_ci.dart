import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import 'ci_trigger.dart';
import 'command_runner.dart';
import 'dart/dart_ci.dart';
import 'firebase/firebase_ci.dart';
import 'firebase_hosting/firebase_hosting_ci.dart';
import 'flutter/flutter_ci.dart';
import 'ios_simulator.dart' as ios;
import 'machine_type.dart';
import 'patrol/patrol_ci.dart';
import 'pull_request_ci.dart';
import 'shorebird/shorebird_ci.dart';
import 'virtual_ble/virtual_ble.dart' as ble;
import 'workspace_directory.dart';
import 'workflow_context.dart';

class OpenCI {
  OpenCI({
    required this.workflowName,
    required List<CITrigger> ciTriggers,
    this.machine = MachineType.macOsLatest,
    this.flutterVersion,
    this.cancelPreviousRuns = false,
    this.currentWorkingDirectory,
    required this.workspacePath,
    @visibleForTesting WorkflowContext? context,
    @visibleForTesting
    Future<void> Function(String command, {required String workingDirectory})
        commandRunner =
        runCommand,
  }) : ciTriggers = List.unmodifiable(ciTriggers),
       _contextOverride = context,
       _runCommand = commandRunner;

  final String workflowName;

  /// Events that can start this workflow. Any matching trigger schedules a run.
  final List<CITrigger> ciTriggers;
  final MachineType machine;

  /// Cancel older opted-in runs of this workflow on the same pull request.
  ///
  /// Use a literal boolean in [init]. Push runs and runs of the same commit
  /// are unaffected. The server applies this option; local runs are unchanged.
  final bool cancelPreviousRuns;

  /// Flutter release selected by CI before resolving the workflow dependencies.
  ///
  /// Use a literal release such as `3.47.8` in [init]. When omitted, CI uses the
  /// image's default SDK. This metadata does not switch the SDK in local runs.
  final String? flutterVersion;
  final String? currentWorkingDirectory;
  final String workspacePath;

  final WorkflowContext? _contextOverride;

  /// The event and checkout for this execution, read once on first access.
  ///
  /// Local execution returns [LocalContext]. A CI executor that does not supply
  /// context throws on access, without affecting workflows that never read it.
  late final WorkflowContext context =
      _contextOverride ?? WorkflowContext.fromEnvironment(Platform.environment);

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

  late final DartCI dart = DartCI(
    run,
    resolveDirectory: (dir) =>
        resolveWorkingDirectory(dir ?? currentWorkingDirectory),
  );

  late final FlutterCI flutter = FlutterCI(run);

  /// Runs the project's Patrol tests on a prepared device or simulator.
  late final PatrolCI patrol = PatrolCI(
    (dir) => resolveWorkingDirectory(dir ?? currentWorkingDirectory),
  );

  /// Deploys static sites to Firebase Hosting, including expiring PR previews.
  late final FirebaseHostingCI firebaseHosting = FirebaseHostingCI(
    (dir) => resolveWorkingDirectory(dir ?? currentWorkingDirectory),
  );

  /// Deploys Firebase resources, including Cloud Functions.
  late final FirebaseCI firebase = FirebaseCI(
    (dir) => resolveWorkingDirectory(dir ?? currentWorkingDirectory),
  );

  final PullRequestCI pullRequest = const PullRequestCI();

  late final ShorebirdCI shorebird = ShorebirdCI(run);

  static Future<OpenCI> init({
    required String workflowName,
    required List<CITrigger> ciTriggers,
    MachineType machine = MachineType.macOsLatest,
    String? flutterVersion,
    bool cancelPreviousRuns = false,
    String? currentWorkingDirectory,
    String? workspacePath,
  }) async {
    final workspace = workspacePath ?? Directory.current.path;

    return OpenCI(
      workflowName: workflowName,
      ciTriggers: ciTriggers,
      machine: machine,
      flutterVersion: flutterVersion,
      cancelPreviousRuns: cancelPreviousRuns,
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

  /// Creates a fresh iOS Simulator and waits until it has finished booting.
  ///
  /// Requires macOS, Xcode, and an installed compatible simulator runtime.
  /// [device] accepts a device type name or identifier. When [runtime] is
  /// omitted, Xcode chooses the newest installed runtime compatible with it.
  /// The default iPhone 17 Pro requires iOS 26 or later.
  ///
  /// Returns its UDID in [ios.IosSimulator.id]. Call [ios.IosSimulator.dispose]
  /// after use to shut down and delete it. Boot failures also trigger cleanup.
  Future<ios.IosSimulator> launchIosSimulator({
    String device = 'iPhone 17 Pro',
    String name = 'OpenCI Simulator',
    String? runtime,
    Duration bootTimeout = const Duration(minutes: 10),
  }) => ios.launchIosSimulator(
    device: device,
    name: name,
    runtime: runtime,
    bootTimeout: bootTimeout,
  );

  /// Starts two virtual GATT peers on this Mac, reachable by iOS simulators.
  ///
  /// Supply 128-bit service and characteristic UUIDs. Requires Python 3.11+
  /// with venv and pip. Call [ble.VirtualBleSession.dispose] in a finally block.
  Future<ble.VirtualBleSession> startVirtualBle({
    required String serviceUuid,
    required String characteristicUuid,
    String pythonExecutable = 'python3.13',
  }) => ble.startVirtualBle(
    serviceUuid: serviceUuid,
    characteristicUuid: characteristicUuid,
    pythonExecutable: pythonExecutable,
  );

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
