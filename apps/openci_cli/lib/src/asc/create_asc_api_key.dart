import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../extensions/file_extensions.dart';
import 'asc_api_key.dart';
import 'asc_authentication_status.dart';

enum AscApiKeyFailure { start, execution, response, storage }

class AscApiKeyException implements Exception {
  const AscApiKeyException(this.failure);

  final AscApiKeyFailure failure;
}

/// Creates one key for the confirmed provider using an already verified asc.
///
/// The caller must reserve and show [outputDirectory] before calling this.
/// Creation is never retried, and downloaded files are retained on failure.
Future<AscApiKey> createAscApiKey(
  File executable,
  String appleId,
  AscAuthenticationStatus status,
  Directory outputDirectory, {
  @visibleForTesting
  Future<Process> Function(String, List<String>) processStarter = Process.start,
}) async {
  final providerId = status.providerId;
  final publicProviderId = status.publicProviderId;
  if (!status.authenticated ||
      (providerId == null && publicProviderId == null) ||
      (providerId != null && providerId <= 0) ||
      (publicProviderId != null && publicProviderId.trim().isEmpty)) {
    throw ArgumentError('An authenticated provider is required.');
  }

  final Process process;
  try {
    process = await processStarter(executable.absolute.path, [
      'web',
      'api-keys',
      'create',
      '--apple-id',
      appleId,
      if (providerId != null) ...['--provider-id', '$providerId'],
      if (publicProviderId != null) ...[
        '--public-provider-id',
        publicProviderId,
      ],
      '--name',
      'GenuineCI',
      '--role',
      'APP_MANAGER',
      '--output-dir',
      outputDirectory.absolute.path,
      '--output',
      'json',
    ]);
  } on ProcessException {
    throw const AscApiKeyException(AscApiKeyFailure.start);
  }

  final bytes = <int>[];
  var outputTooLarge = false;
  final stdout = process.stdout.listen((chunk) {
    if (!outputTooLarge && bytes.length + chunk.length <= 16 * 1024) {
      bytes.addAll(chunk);
    } else {
      outputTooLarge = true;
    }
  });
  // asc uses /dev/tty for any reauthentication prompts. Do not print raw JSON
  // or diagnostics containing account/session details.
  final stderr = process.stderr.listen(null);
  final exitCode = process.exitCode;
  var completed = false;
  try {
    // asc bounds its network requests after authentication. An outer timeout
    // could kill it during a password prompt or its one-time key download.
    final results = await Future.wait<Object?>([
      exitCode,
      stdout.asFuture<void>(),
      stderr.asFuture<void>(),
      process.stdin.close(),
    ], eagerError: true);
    completed = true;
    if (results.first != 0) {
      throw const AscApiKeyException(AscApiKeyFailure.execution);
    }
    if (outputTooLarge) {
      throw const AscApiKeyException(AscApiKeyFailure.response);
    }

    final response = jsonDecode(utf8.decode(bytes));
    if (response is! Map<String, dynamic>) {
      throw const AscApiKeyException(AscApiKeyFailure.response);
    }
    final keyId = response['keyId'];
    final issuerId = response['issuerId'];
    final p8Path = response['p8Path'];
    final roles = response['roles'];
    if (keyId is! String ||
        !RegExp(r'^[A-Za-z0-9]+$').hasMatch(keyId) ||
        issuerId is! String ||
        issuerId.trim().isEmpty ||
        RegExp(r'[\x00-\x1f\x7f-\x9f]').hasMatch(issuerId) ||
        p8Path is! String ||
        roles is! List ||
        roles.length != 1 ||
        roles.single != 'APP_MANAGER' ||
        response['active'] != true) {
      throw const AscApiKeyException(AscApiKeyFailure.response);
    }

    final privateKeyFile = File(
      p.join(outputDirectory.absolute.path, 'AuthKey_$keyId.p8'),
    );
    if (!p.equals(p.normalize(p8Path), privateKeyFile.path) ||
        await FileSystemEntity.type(privateKeyFile.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await privateKeyFile.length() == 0) {
      throw const AscApiKeyException(AscApiKeyFailure.response);
    }

    final key = AscApiKey(
      keyId: keyId,
      issuerId: issuerId.trim(),
      privateKeyFile: privateKeyFile,
    );
    await File(p.join(outputDirectory.path, 'key.json')).writeAsStringAtomic(
      jsonEncode({
        'keyId': key.keyId,
        'issuerId': key.issuerId,
        'providerId': ?providerId,
        'publicProviderId': ?publicProviderId,
        'role': 'APP_MANAGER',
        'p8Path': key.privateKeyFile.path,
      }),
      chmod600: true,
    );
    return key;
  } on FormatException {
    throw const AscApiKeyException(AscApiKeyFailure.response);
  } on ProcessException {
    throw const AscApiKeyException(AscApiKeyFailure.storage);
  } on IOException {
    throw AscApiKeyException(
      completed ? AscApiKeyFailure.storage : AscApiKeyFailure.execution,
    );
  } finally {
    if (!completed) {
      process.kill();
      try {
        await exitCode.timeout(const Duration(seconds: 1));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
      }
    }
    await stdout.cancel();
    await stderr.cancel();
  }
}
