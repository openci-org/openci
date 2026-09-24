import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';

typedef LoginCredentials = ({String email, String password});

Future<LoginCredentials?> readLoginCredentials({
  @visibleForTesting Stdin? input,
  @visibleForTesting Stdout? output,
  @visibleForTesting Stream<ProcessSignal>? interruptSignals,
}) async {
  final terminal = input ?? stdin;
  final prompt = output ?? stderr;
  if (!terminal.hasTerminal) return null;

  final echoMode = terminal.echoMode;
  final lines = StreamIterator(
    terminal.transform(utf8.decoder).transform(const LineSplitter()),
  );
  final cancelled = Completer<bool>();
  final signals =
      [
            if (interruptSignals != null)
              interruptSignals
            else ...[
              ProcessSignal.sigint.watch(),
              if (!Platform.isWindows) ProcessSignal.sigterm.watch(),
            ],
          ]
          .map(
            (signal) => signal.listen((_) {
              if (!cancelled.isCompleted) cancelled.complete(false);
            }),
          )
          .toList();

  Future<String?> readLine() async {
    final hasLine = await Future.any([lines.moveNext(), cancelled.future]);
    return hasLine ? lines.current : null;
  }

  try {
    prompt.write(t.login.emailPrompt);
    final email = await readLine();
    if (email == null || email.trim().isEmpty) return null;
    terminal.echoMode = false;
    prompt.write(t.login.passwordPrompt);
    final password = await readLine();
    if (password == null || password.isEmpty) return null;
    return (email: email.trim(), password: password);
  } finally {
    terminal.echoMode = echoMode;
    prompt.writeln();
    await lines.cancel();
    for (final subscription in signals) {
      await subscription.cancel();
    }
  }
}
