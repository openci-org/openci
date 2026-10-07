import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';

enum AppleIdInputFailure { notInteractive, read }

class AppleIdInputException implements Exception {
  const AppleIdInputException(this.failure);

  final AppleIdInputFailure failure;
}

/// Reads an Apple ID without closing stdin or changing terminal modes.
Future<String?> readAppleId({
  @visibleForTesting Stdin? input,
  @visibleForTesting Stdout? output,
}) async {
  final terminal = input ?? stdin;
  final prompt = output ?? stderr;
  try {
    if (!terminal.hasTerminal || !prompt.hasTerminal) {
      throw const AppleIdInputException(AppleIdInputFailure.notInteractive);
    }

    prompt.write(t.setup.ascKeys.appleIdPrompt);
    await prompt.flush();
    // Cancelling an async stdin subscription closes fd 0. A synchronous read
    // leaves it available for asc to inherit later and preserves normal SIGINT.
    final appleId = terminal.readLineSync(encoding: utf8)?.trim();
    if (appleId == null) prompt.writeln();
    return appleId == null || appleId.isEmpty ? null : appleId;
  } on IOException {
    throw const AppleIdInputException(AppleIdInputFailure.read);
  } on FormatException {
    throw const AppleIdInputException(AppleIdInputFailure.read);
  }
}
