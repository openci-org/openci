import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'asc_release.dart';

enum AscVerificationFailure { checksum, execution, timeout, version }

class AscVerificationException implements Exception {
  const AscVerificationException(this.failure);

  final AscVerificationFailure failure;
}

/// Verifies the cached binary's integrity before running its version command.
Future<void> verifyAscExecutable(
  File executable, {
  @visibleForTesting String expectedChecksum = ascChecksum,
  @visibleForTesting
  Future<Process> Function(String, List<String>) processStarter = Process.start,
  @visibleForTesting Duration timeout = const Duration(seconds: 10),
}) async {
  final file = executable.absolute;
  final type = await FileSystemEntity.type(file.path, followLinks: false);
  if (type != FileSystemEntityType.file) {
    throw FileSystemException(
      'The asc cache path is not a regular file.',
      file.path,
    );
  }
  final checksum = (await sha256.bind(file.openRead()).first).toString();
  if (checksum != expectedChecksum) {
    throw const AscVerificationException(AscVerificationFailure.checksum);
  }

  final output = await _runVersion(file.path, processStarter, timeout);
  // Release binaries include commit and date metadata after the version number.
  final version = RegExp(
    r'^(\d+\.\d+\.\d+)(?: \([^\r\n]*\))?$',
  ).firstMatch(output.trim())?.group(1);
  if (version != ascVersion) {
    throw const AscVerificationException(AscVerificationFailure.version);
  }
}

Future<String> _runVersion(
  String executable,
  Future<Process> Function(String, List<String>) processStarter,
  Duration timeout,
) async {
  final Process process;
  try {
    process = await processStarter(executable, const ['version']);
  } on ProcessException {
    throw const AscVerificationException(AscVerificationFailure.execution);
  }

  final bytes = <int>[];
  var outputTooLarge = false;
  final stdout = process.stdout.listen((chunk) {
    if (!outputTooLarge && bytes.length + chunk.length <= 4096) {
      bytes.addAll(chunk);
    } else {
      outputTooLarge = true;
    }
  });
  // Drain stderr concurrently so a full pipe cannot block the version command.
  final stderr = process.stderr.listen(null);
  final exitCode = process.exitCode;
  var completed = false;
  try {
    final results = await Future.wait<Object?>([
      exitCode,
      stdout.asFuture<void>(),
      stderr.asFuture<void>(),
      process.stdin.close(),
    ], eagerError: true).timeout(timeout);
    completed = true;
    if (results.first != 0) {
      throw const AscVerificationException(AscVerificationFailure.execution);
    }
    if (outputTooLarge) {
      throw const AscVerificationException(AscVerificationFailure.version);
    }
    return utf8.decode(bytes);
  } on TimeoutException {
    throw const AscVerificationException(AscVerificationFailure.timeout);
  } on IOException {
    throw const AscVerificationException(AscVerificationFailure.execution);
  } on FormatException {
    throw const AscVerificationException(AscVerificationFailure.version);
  } finally {
    if (!completed) {
      process.kill(ProcessSignal.sigkill);
      try {
        await exitCode.timeout(const Duration(seconds: 1));
      } on TimeoutException {
        // Do not leave setup waiting indefinitely if the OS cannot reap it.
      }
    }
    await stdout.cancel();
    await stderr.cancel();
  }
}
