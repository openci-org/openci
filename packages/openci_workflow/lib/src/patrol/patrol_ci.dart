import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../secret.dart';

class PatrolCI {
  const PatrolCI(
    this._resolveDirectory, {
    @visibleForTesting PatrolProcessRunner processRunner = runPatrolProcess,
  }) : _processRunner = processRunner;

  final String Function(String? dir) _resolveDirectory;
  final PatrolProcessRunner _processRunner;

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
          if (defines != null)
            '--dart-define-from-file=${defines.absolute.path}',
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
    } finally {
      await temp?.delete(recursive: true);
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
