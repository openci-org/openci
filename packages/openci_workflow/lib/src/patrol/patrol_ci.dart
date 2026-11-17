import 'dart:io';

import 'package:meta/meta.dart';

/// Runs the project's resolved Patrol CLI using the workflow's Dart toolchain.
class PatrolCI {
  const PatrolCI(
    this._resolveDirectory, {
    @visibleForTesting PatrolProcessRunner processRunner = runPatrolProcess,
  }) : _processRunner = processRunner;

  final String Function(String? dir) _resolveDirectory;
  final PatrolProcessRunner _processRunner;

  /// Builds and runs Patrol tests on an available [device] ID or name.
  ///
  /// Runs `dart run patrol_cli:main test` in the workflow directory, or [dir].
  /// The project must resolve `patrol_cli` and have Patrol's native setup.
  /// This does not install the CLI or provision a device.
  ///
  /// Empty [targets] uses Patrol's configured test directory. Each item in
  /// [additionalArguments] is one CLI argument, passed without a shell; Patrol's
  /// own argument parsing still applies. Use it for flavors, Dart defines, tags,
  /// build modes, or other CLI options.
  ///
  /// Output streams to the workflow log. A nonzero exit throws [ProcessException]
  /// instead of terminating the workflow process, so `finally` can clean up.
  Future<void> test({
    required String device,
    String? dir,
    List<String> targets = const [],
    bool verbose = false,
    List<String> additionalArguments = const [],
  }) async {
    if (device.trim().isEmpty) {
      throw ArgumentError.value(device, 'device', 'Specify a test device.');
    }
    if (targets.any((target) => target.trim().isEmpty)) {
      throw ArgumentError.value(
        targets,
        'targets',
        'Targets must not be empty.',
      );
    }
    final result = await _processRunner(
      'dart',
      [
        'run',
        'patrol_cli:main',
        if (verbose) '--verbose',
        'test',
        '--device',
        device,
        for (final target in targets) ...['--target', target],
        ...additionalArguments,
      ],
      workingDirectory: _resolveDirectory(dir),
    );
    if (result != 0) {
      // Additional arguments may contain credentials. Keep them out of errors.
      throw ProcessException(
        'dart',
        const ['run', 'patrol_cli:main', 'test'],
        'Patrol tests failed. See the command output above.',
        result,
      );
    }
  }
}

typedef PatrolProcessRunner =
    Future<int> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
    });

Future<int> runPatrolProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final Process process;
  try {
    process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.inheritStdio,
    );
  } on ProcessException catch (error) {
    // Preserve the OS diagnostic without echoing potentially sensitive options.
    throw ProcessException(
      executable,
      const [],
      error.message,
      error.errorCode,
    );
  }
  return process.exitCode;
}
