import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openci_cli/src/commands/login/read_login_credentials.dart';
import 'package:openci_cli/src/i18n/i18n.dart';
import 'package:test/test.dart';

class _Input extends Stream<List<int>> implements Stdin {
  final controller = StreamController<List<int>>();

  @override
  bool echoMode = true;
  @override
  bool hasTerminal = true;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => controller.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Output implements Stdout {
  final void Function(Object?) onWrite;
  _Output(this.onWrite);
  @override
  void write(Object? object) => onWrite(object);
  @override
  void writeln([Object? object = '']) => onWrite(object);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'hides the password, trims the email and restores terminal echo',
    () async {
      final input = _Input();
      addTearDown(input.controller.close);
      final messages = <Object?>[];
      final output = _Output((message) {
        messages.add(message);
        if (message == t.login.emailPrompt) {
          expect(input.echoMode, isTrue);
          input.controller.add(utf8.encode(' user@example.com \n'));
        } else if (message == t.login.passwordPrompt) {
          expect(input.echoMode, isFalse);
          input.controller.add(utf8.encode(' private password 日本語 \n'));
        }
      });

      final credentials = await readLoginCredentials(
        input: input,
        output: output,
        interruptSignals: const Stream.empty(),
      );

      expect(credentials, (
        email: 'user@example.com',
        password: ' private password 日本語 ',
      ));
      expect(input.echoMode, isTrue);
      expect(messages.join(), isNot(contains('private password')));
    },
  );

  test('cancelling during password input restores terminal echo', () async {
    final input = _Input();
    final signals = StreamController<ProcessSignal>();
    addTearDown(input.controller.close);
    addTearDown(signals.close);
    final output = _Output((message) {
      if (message == t.login.emailPrompt) {
        input.controller.add(utf8.encode('user@example.com\n'));
      } else if (message == t.login.passwordPrompt) {
        expect(input.echoMode, isFalse);
        signals.add(ProcessSignal.sigint);
      }
    });

    final credentials = await readLoginCredentials(
      input: input,
      output: output,
      interruptSignals: signals.stream,
    );

    expect(credentials, isNull);
    expect(input.echoMode, isTrue);
  });

  test('requires a terminal before reading input or changing echo', () async {
    final input = _Input()..hasTerminal = false;
    final messages = <Object?>[];

    expect(
      await readLoginCredentials(input: input, output: _Output(messages.add)),
      isNull,
    );
    expect(input.echoMode, isTrue);
    expect(input.controller.hasListener, isFalse);
    expect(messages, isEmpty);
  });
}
