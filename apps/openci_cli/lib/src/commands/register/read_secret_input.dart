import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';

typedef SecretInput = ({String name, String value});

Future<SecretInput?> readSecretInput({
  @visibleForTesting Stdin? input,
  @visibleForTesting Logger? logger,
}) async {
  if (!(input ?? stdin).hasTerminal) return null;

  final prompt = logger ?? Logger();
  final name = prompt.prompt(t.register.secret.namePrompt).trim();
  if (name.isEmpty) return null;

  final value = prompt.prompt(t.register.secret.valuePrompt, hidden: true);
  return (name: name, value: value);
}
