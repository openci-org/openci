import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:genuineci_cli/src/commands/setup/read_apple_id.dart';
import 'package:genuineci_cli/src/i18n/i18n.dart';
import 'package:test/test.dart';

class _Input extends Stream<List<int>> implements Stdin {
  @override
  bool hasTerminal = true;
  String? line = ' user@example.com ';
  Object? error;
  int reads = 0;
  void Function()? onRead;

  @override
  String? readLineSync({
    Encoding encoding = systemEncoding,
    bool retainNewlines = false,
  }) {
    reads++;
    onRead?.call();
    if (error != null) throw error!;
    return line;
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      throw StateError('Async stdin reads can close the inherited descriptor');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Output implements Stdout {
  @override
  bool hasTerminal = true;
  final messages = <Object?>[];
  bool flushed = false;
  Completer<void>? flushWaiter;

  @override
  void write(Object? message) => messages.add(message);

  @override
  void writeln([Object? message = '']) => messages.add('$message\n');

  @override
  Future<void> flush() async {
    await flushWaiter?.future;
    flushed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppLocale originalLocale;
  late _Input input;
  late _Output output;

  setUp(() {
    originalLocale = LocaleSettings.currentLocale;
    input = _Input();
    output = _Output();
  });

  tearDown(() => LocaleSettings.setLocaleSync(originalLocale));

  Future<String?> read() => readAppleId(input: input, output: output);

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    test(
      'prompts in $locale and trims the email without reprinting it',
      () async {
        LocaleSettings.setLocaleSync(locale);
        input.onRead = () => expect(output.flushed, isTrue);

        expect(await read(), 'user@example.com');

        expect(input.reads, 1);
        expect(output.messages, [t.setup.ascKeys.appleIdPrompt]);
      },
    );
  }

  test('waits for the prompt to flush before blocking for input', () async {
    output.flushWaiter = Completer<void>();
    final result = read();

    expect(input.reads, 0);
    expect(output.messages, [t.setup.ascKeys.appleIdPrompt]);
    output.flushWaiter!.complete();

    expect(await result, 'user@example.com');
    expect(input.reads, 1);
  });

  for (final line in [null, '', ' \t ']) {
    test('stops on ${line == null ? 'EOF' : 'blank input'}', () async {
      input.line = line;

      expect(await read(), isNull);

      expect(input.reads, 1);
      expect(output.messages, [
        t.setup.ascKeys.appleIdPrompt,
        if (line == null) '\n',
      ]);
    });
  }

  for (final inputIsTerminal in [true, false]) {
    test(
      'requires a terminal for ${inputIsTerminal ? 'the prompt' : 'input'}',
      () async {
        input.hasTerminal = inputIsTerminal;
        output.hasTerminal = !inputIsTerminal;

        await expectLater(
          read(),
          throwsA(
            isA<AppleIdInputException>().having(
              (error) => error.failure,
              'failure',
              AppleIdInputFailure.notInteractive,
            ),
          ),
        );

        expect(input.reads, 0);
        expect(output.messages, isEmpty);
        expect(output.flushed, isFalse);
      },
    );
  }

  for (final error in [
    const StdinException('input unavailable'),
    const FormatException('invalid encoding'),
  ]) {
    test('reports ${error.runtimeType} without exposing its details', () async {
      input.error = error;

      await expectLater(
        read(),
        throwsA(
          isA<AppleIdInputException>().having(
            (error) => error.failure,
            'failure',
            AppleIdInputFailure.read,
          ),
        ),
      );

      expect(output.messages, [t.setup.ascKeys.appleIdPrompt]);
    });
  }
}
