import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';

class AscKeyConfirmationException implements Exception {
  const AscKeyConfirmationException();
}

/// Confirms creation without closing stdin needed by asc's terminal prompts.
Future<bool> confirmAscKeyCreation({
  @visibleForTesting Stdin? input,
  @visibleForTesting Stdout? output,
}) async {
  final terminal = input ?? stdin;
  final prompt = output ?? stderr;
  try {
    if (!terminal.hasTerminal || !prompt.hasTerminal) {
      throw const AscKeyConfirmationException();
    }
    prompt.write(t.setup.ascKeys.confirmKeyCreation);
    await prompt.flush();
    final answer = terminal.readLineSync(encoding: utf8)?.trim().toLowerCase();
    if (answer == null) prompt.writeln();
    return answer == 'y' || answer == 'yes';
  } on IOException {
    throw const AscKeyConfirmationException();
  } on FormatException {
    throw const AscKeyConfirmationException();
  }
}
