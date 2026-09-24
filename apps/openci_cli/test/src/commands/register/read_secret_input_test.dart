import 'dart:io';

import 'package:openci_cli/src/commands/register/read_secret_input.dart';
import 'package:openci_cli/src/i18n/i18n.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

class _Input implements Stdin {
  _Input({this.hasTerminal = true});

  @override
  final bool hasTerminal;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PromptLogger implements Logger {
  _PromptLogger(this.answers);

  final List<String> answers;
  final prompts = <({String? message, bool hidden})>[];

  @override
  String prompt(String? message, {Object? defaultValue, bool hidden = false}) {
    prompts.add((message: message, hidden: hidden));
    return answers.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('asks for a visible name followed by a hidden value', () async {
    final logger = _PromptLogger([' API_TOKEN ', ' private value 日本語 🚀 ']);

    expect(await readSecretInput(input: _Input(), logger: logger), (
      name: 'API_TOKEN',
      value: ' private value 日本語 🚀 ',
    ));
    expect(logger.prompts, [
      (message: t.register.secret.namePrompt, hidden: false),
      (message: t.register.secret.valuePrompt, hidden: true),
    ]);
  });

  test('does not ask for a value when the name is blank', () async {
    final logger = _PromptLogger(['   ']);

    expect(await readSecretInput(input: _Input(), logger: logger), isNull);
    expect(logger.prompts, [
      (message: t.register.secret.namePrompt, hidden: false),
    ]);
  });

  test('does not prompt or read redirected input without a terminal', () async {
    final logger = _PromptLogger([]);

    expect(
      await readSecretInput(input: _Input(hasTerminal: false), logger: logger),
      isNull,
    );
    expect(logger.prompts, isEmpty);
  });
}
