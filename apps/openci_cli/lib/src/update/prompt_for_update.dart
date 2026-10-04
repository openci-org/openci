import 'dart:io';

import 'package:meta/meta.dart';

import '../i18n/i18n.dart';

bool promptForUpdate({
  @visibleForTesting Stdin? input,
  @visibleForTesting Stdout? output,
}) {
  final terminal = input ?? stdin;
  final prompt = output ?? stderr;
  prompt.write('${t.update.confirm} [y/N] ');
  try {
    final answer = terminal.readLineSync()?.trim().toLowerCase();
    return answer == 'y' || answer == 'yes';
  } on FormatException {
    return false;
  }
}
