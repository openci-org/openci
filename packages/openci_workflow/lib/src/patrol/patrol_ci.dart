import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../secret.dart';
import 'virtual_ble_patrol.dart';

class PatrolCI {
  const PatrolCI(
    this._resolveDirectory, {
    @visibleForTesting PatrolProcessRunner processRunner = runPatrolProcess,
  }) : _processRunner = processRunner;

  final String Function(String? dir) _resolveDirectory;
  final PatrolProcessRunner _processRunner;

  /// Builds one Debug iOS app, then runs [target] on two fresh simulators.
  ///
  /// Each app receives its peer URL in tmp/openci-virtual-ble.json. B publishes
  /// first. Both Patrol runs must succeed and both apps must publish to GATT.
  /// The returned directory holds A/B logs and links to the XCTest results.
  /// If supplied, [resultJsonFile] in each app's tmp directory is required and
  /// copied to A.json or B.json before the simulators are deleted.
  Future<Directory> testWithVirtualBle({
    String? dir,
    required String target,
    required String bundleId,
    required String serviceUuid,
    required String characteristicUuid,
    String? resultJsonFile,
    String pythonExecutable = 'python3.13',
  }) async {
    if (target.trim().isEmpty || bundleId.trim().isEmpty) {
      throw ArgumentError('Specify a Patrol target and iOS bundle identifier.');
    }
    if (resultJsonFile != null &&
        (resultJsonFile.contains('/') || !resultJsonFile.endsWith('.json'))) {
      throw ArgumentError.value(
        resultJsonFile,
        'resultJsonFile',
        'Expected a JSON file name',
      );
    }
    final directory = _resolveDirectory(dir);
    await _runCli('build', [
      'ios',
      '--simulator',
      '--emit-test-manifest',
      '--target',
      target,
    ], directory: directory);
    return runVirtualBlePatrol(
      directory: Directory(directory).absolute,
      target: target,
      bundleId: bundleId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      resultJsonFile: resultJsonFile,
      pythonExecutable: pythonExecutable,
    );
  }

  Future<void> test({
    required String device,
    String? dir,
    List<String> targets = const [],
    List<Secret> env = const [],
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
    final values = <String, String>{};
    for (final secret in env) {
      final value = secret.value;
      if (value.isEmpty) {
        throw StateError("Secret '${secret.key}' is empty.");
      }
      values[secret.key] = value;
    }
    Directory? temp;
    try {
      File? defines;
      if (values.isNotEmpty) {
        temp = await Directory.systemTemp.createTemp('openci-patrol-');
        defines = File.fromUri(temp.uri.resolve('defines.json'));
        await defines.writeAsString(jsonEncode(values));
      }
      await _runCli(
        'test',
        [
          '--device',
          device,
          for (final target in targets) ...['--target', target],
          if (defines != null)
            '--dart-define-from-file=${defines.absolute.path}',
          ...additionalArguments,
        ],
        directory: _resolveDirectory(dir),
        verbose: verbose,
      );
    } finally {
      await temp?.delete(recursive: true);
    }
  }

  Future<void> _runCli(
    String command,
    List<String> arguments, {
    required String directory,
    bool verbose = false,
  }) async {
    final cli = ['run', 'patrol_cli:main'];
    final code = await _processRunner(
      'dart',
      [...cli, if (verbose) '--verbose', command, ...arguments],
      workingDirectory: directory,
    );
    if (code != 0) {
      // Additional arguments may contain credentials. Keep them out of errors.
      final operation = command == 'test' ? 'tests' : command;
      throw ProcessException(
        'dart',
        [...cli, command],
        'Patrol $operation failed. See the command output above.',
        code,
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
