import 'dart:async';
import 'dart:io';

import 'package:genuineci_cli/src/terminal/console.dart';
import 'package:genuineci_cli/src/terminal/interactive_console.dart';
import 'package:test/test.dart';

class _Console implements Console {
  final output = StringBuffer();
  Stream<Key> keyboard = const Stream.empty();
  bool failReading = false;

  @override
  bool rawMode = false;

  @override
  Stream<Key> readKeys({
    Duration escapeTimeout = const Duration(milliseconds: 100),
  }) {
    if (failReading) throw StateError('read failed');
    return keyboard;
  }

  @override
  void write(Object text) => output.write(text);

  @override
  void writeLine([
    Object? text,
    TextAlignment alignment = TextAlignment.left,
  ]) => output.writeln(text ?? '');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'listens before rendering and cancels input even if it is not consumed',
    () async {
      final console = _Console()..rawMode = true;
      var subscribed = false;
      var cancelled = false;
      final input = StreamController<Key>(
        onListen: () {
          subscribed = true;
          console.rawMode = true;
        },
        onCancel: () {
          cancelled = true;
          console.rawMode = false;
        },
      );

      expect(
        await withInteractiveConsole<String>(
          (terminal, keys) async {
            expect(subscribed, isTrue);
            expect(terminal, same(console));
            terminal.write('render');
            return 'selected';
          },
          console: console,
          keys: input.stream,
          hasTerminal: true,
          hideCursor: true,
        ),
        'selected',
      );
      expect(cancelled, isTrue);
      expect(console.rawMode, isTrue);
      expect(console.output.toString(), '\x1b[?25lrender\x1b[?25h\n');
      await input.close();
    },
  );

  test(
    'leaves cursor visibility unchanged when hiding is not requested',
    () async {
      final console = _Console();
      expect(
        await withInteractiveConsole<String>(
          (terminal, keys) async => (await keys.first).char,
          console: console,
          keys: Stream.value(Key.printable('a')),
          hasTerminal: true,
        ),
        'a',
      );
      expect(console.output.toString(), '\n');
      expect(console.rawMode, isFalse);
    },
  );

  test('still restores terminal state if stream cancellation fails', () async {
    final console = _Console();
    final input = StreamController<Key>(
      onListen: () => console.rawMode = true,
      onCancel: () => throw StateError('cancel failed'),
    );
    await expectLater(
      withInteractiveConsole<String>(
        (_, keys) async => 'selected',
        console: console,
        keys: input.stream,
        hasTerminal: true,
        hideCursor: true,
      ),
      throwsStateError,
    );
    expect(console.rawMode, isFalse);
    expect(console.output.toString(), '\x1b[?25l\x1b[?25h\n');
    await input.close();
  });

  test(
    'forwards keyboard events and errors, then closes and cancels signals',
    () async {
      final console = _Console();
      var keyboardCancelled = false;
      var signalCancelled = false;
      final keyboard = StreamController<Key>(
        onCancel: () => keyboardCancelled = true,
      );
      final signal = StreamController<ProcessSignal>(
        onCancel: () => signalCancelled = true,
      );
      console.keyboard = keyboard.stream;
      final keys = <Key>[];
      final errors = <Object>[];
      final done = Completer<void>();
      readInteractiveKeys(
        console,
        signals: [signal.stream],
      ).listen(keys.add, onError: errors.add, onDone: done.complete);
      final key = Key.printable('a');
      final error = StateError('keyboard failed');
      keyboard.add(key);
      keyboard.addError(error);
      await keyboard.close();
      await done.future;

      expect(keys, [same(key)]);
      expect(errors, [same(error)]);
      expect(keyboardCancelled, isTrue);
      expect(signalCancelled, isTrue);
      await signal.close();
    },
  );

  for (final processSignal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
    test(
      'converts $processSignal to cancellation and releases all subscriptions',
      () async {
        final console = _Console();
        var keyboardSubscribed = false;
        var keyboardCancelled = false;
        var signalSubscribed = false;
        var signalCancelled = false;
        var otherSignalCancelled = false;
        final keyboard = StreamController<Key>(
          onListen: () => keyboardSubscribed = true,
          onCancel: () => keyboardCancelled = true,
        );
        final signal = StreamController<ProcessSignal>(
          onListen: () => signalSubscribed = true,
          onCancel: () => signalCancelled = true,
        );
        final otherSignal = StreamController<ProcessSignal>(
          onCancel: () => otherSignalCancelled = true,
        );
        console.keyboard = keyboard.stream;
        final first = readInteractiveKeys(
          console,
          signals: [signal.stream, otherSignal.stream],
        ).first;
        expect(keyboardSubscribed, isTrue);
        expect(signalSubscribed, isTrue);
        signal.add(processSignal);

        expect((await first).controlChar, ControlCharacter.ctrlC);
        expect(keyboardCancelled, isTrue);
        expect(signalCancelled, isTrue);
        expect(otherSignalCancelled, isTrue);
        await Future.wait([
          keyboard.close(),
          signal.close(),
          otherSignal.close(),
        ]);
      },
    );
  }

  test(
    'releases signal watchers when starting the key reader throws',
    () async {
      final console = _Console()..failReading = true;
      var cancelled = false;
      final signal = StreamController<ProcessSignal>(
        onCancel: () => cancelled = true,
      );

      await expectLater(
        readInteractiveKeys(console, signals: [signal.stream]).toList(),
        throwsStateError,
      );
      expect(cancelled, isTrue);
      await signal.close();
    },
  );
}
