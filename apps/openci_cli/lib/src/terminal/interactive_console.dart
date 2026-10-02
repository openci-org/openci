import 'dart:async';
import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:meta/meta.dart';

bool get hasInteractiveTerminal =>
    stdin.hasTerminal && stdout.hasTerminal && stdout.supportsAnsiEscapes;

Future<T?> withInteractiveConsole<T>(
  Future<T?> Function(Console terminal, Stream<Key> keys) action, {
  Console? console,
  Stream<Key>? keys,
  bool? hasTerminal,
  bool hideCursor = false,
}) async {
  if (!(hasTerminal ?? hasInteractiveTerminal)) {
    return null;
  }
  final terminal = console ?? Console();
  final wasRaw = terminal.rawMode;
  StreamIterator<Key>? input;
  try {
    // Listen before rendering so signals are handled even during the first draw.
    input = StreamIterator(keys ?? readInteractiveKeys(terminal));
    final first = input.moveNext();
    // A failed render may exit without consuming this pending event.
    first.ignore();
    if (hideCursor) terminal.write('\x1b[?25l');
    return await action(terminal, _iterateKeys(input, first));
  } finally {
    try {
      await input?.cancel();
    } finally {
      try {
        terminal.rawMode = wasRaw;
      } finally {
        if (hideCursor) terminal.write('\x1b[?25h');
        terminal.writeLine();
      }
    }
  }
}

Stream<Key> _iterateKeys(StreamIterator<Key> input, Future<bool> first) async* {
  var hasNext = await first;
  while (hasNext) {
    yield input.current;
    hasNext = await input.moveNext();
  }
}

bool isCancelKey(Key key) =>
    key.controlChar == ControlCharacter.escape ||
    key.controlChar == ControlCharacter.ctrlC ||
    key.controlChar == ControlCharacter.ctrlD;

Stream<Key> readInteractiveKeys(
  Console terminal, {
  @visibleForTesting Iterable<Stream<ProcessSignal>>? signals,
}) {
  late StreamController<Key> controller;
  StreamSubscription<Key>? keyboard;
  final subscriptions = <StreamSubscription<ProcessSignal>>[];
  controller = StreamController<Key>(
    onListen: () {
      try {
        for (final signal
            in signals ??
                [
                  ProcessSignal.sigint.watch(),
                  if (!Platform.isWindows) ProcessSignal.sigterm.watch(),
                ]) {
          subscriptions.add(
            signal.listen((_) {
              if (!controller.isClosed) {
                controller.add(Key.control(ControlCharacter.ctrlC));
              }
            }, onError: controller.addError),
          );
        }
        keyboard = terminal.readKeys().listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
        unawaited(controller.close());
      }
    },
    onCancel: () => Future.wait([
      if (keyboard != null) keyboard!.cancel(),
      for (final subscription in subscriptions) subscription.cancel(),
    ]),
  );
  return controller.stream;
}
