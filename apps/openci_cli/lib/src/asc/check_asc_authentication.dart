import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import 'asc_authentication_status.dart';

enum AscAuthenticationFailure { execution, timeout, response }

class AscAuthenticationException implements Exception {
  const AscAuthenticationException(this.failure);

  final AscAuthenticationFailure failure;
}

/// Checks the selected Apple ID's session using an already verified asc binary.
Future<AscAuthenticationStatus> checkAscAuthentication(
  File executable,
  String appleId, {
  @visibleForTesting
  Future<Process> Function(String, List<String>) processStarter = Process.start,
  @visibleForTesting Duration timeout = const Duration(seconds: 30),
}) async {
  final Process process;
  try {
    process = await processStarter(executable.absolute.path, [
      'web',
      'auth',
      'status',
      '--apple-id',
      appleId,
      '--output',
      'json',
    ]);
  } on ProcessException {
    throw const AscAuthenticationException(AscAuthenticationFailure.execution);
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
  // Drain diagnostics without retaining or printing account/session details.
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
      throw const AscAuthenticationException(
        AscAuthenticationFailure.execution,
      );
    }
    if (outputTooLarge) {
      throw const AscAuthenticationException(AscAuthenticationFailure.response);
    }

    final response = jsonDecode(utf8.decode(bytes));
    if (response is! Map<String, dynamic> ||
        response['authenticated'] is! bool) {
      throw const AscAuthenticationException(AscAuthenticationFailure.response);
    }
    final providerName = response['providerName'];
    final providerId = response['providerId'];
    final publicProviderId = response['publicProviderId'];
    if (providerName is! String? ||
        providerId is! int? ||
        (providerId != null && providerId <= 0) ||
        publicProviderId is! String?) {
      throw const AscAuthenticationException(AscAuthenticationFailure.response);
    }
    final trimmedProviderName = providerName?.trim();
    final trimmedPublicProviderId = publicProviderId?.trim();
    for (final value in [trimmedProviderName, trimmedPublicProviderId]) {
      if (value != null && RegExp(r'[\x00-\x1f\x7f-\x9f]').hasMatch(value)) {
        throw const AscAuthenticationException(
          AscAuthenticationFailure.response,
        );
      }
    }
    // asc also exits with code 0 when no valid session exists.
    return AscAuthenticationStatus(
      authenticated: response['authenticated'] as bool,
      providerName: trimmedProviderName == '' ? null : trimmedProviderName,
      providerId: providerId,
      publicProviderId: trimmedPublicProviderId == ''
          ? null
          : trimmedPublicProviderId,
    );
  } on TimeoutException {
    throw const AscAuthenticationException(AscAuthenticationFailure.timeout);
  } on IOException {
    throw const AscAuthenticationException(AscAuthenticationFailure.execution);
  } on FormatException {
    throw const AscAuthenticationException(AscAuthenticationFailure.response);
  } finally {
    if (!completed) {
      process.kill(ProcessSignal.sigkill);
      try {
        await exitCode.timeout(const Duration(seconds: 1));
      } on TimeoutException {
        // Do not wait indefinitely if the OS cannot reap the process.
      }
    }
    await stdout.cancel();
    await stderr.cancel();
  }
}
