import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:genuineci_cli/src/commands/setup/confirm_asc_key_creation.dart';
import 'package:genuineci_cli/src/i18n/i18n.dart';
import 'package:test/test.dart';

class _Input extends Stream<List<int>> implements Stdin {
  @override
  bool hasTerminal = true;
  String? line;
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
  }) => throw StateError('Do not close the inherited stdin descriptor');

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

  Future<bool> confirm() => confirmAscKeyCreation(input: input, output: output);

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    for (final answer in [
      'y',
      'yes',
      ' Y ',
      ' YES ',
      'n',
      'no',
      '',
      'はい',
      null,
    ]) {
      test('confirms only y/yes ($answer, $locale)', () async {
        LocaleSettings.setLocaleSync(locale);
        input.line = answer;
        input.onRead = () => expect(output.flushed, isTrue);

        expect(
          await confirm(),
          ['y', 'yes'].contains(answer?.trim().toLowerCase()),
        );
        expect(input.reads, 1);
        expect(output.messages, [
          t.setup.ascKeys.confirmKeyCreation,
          if (answer == null) '\n',
        ]);
      });
    }
  }

  test('flushes the full prompt before waiting for input', () async {
    output.flushWaiter = Completer<void>();
    final result = confirm();
    expect(input.reads, 0);
    output.flushWaiter!.complete();
    expect(await result, isFalse);
    expect(input.reads, 1);
  });

  for (final inputIsTerminal in [true, false]) {
    test(
      'rejects redirected ${inputIsTerminal ? 'output' : 'input'}',
      () async {
        input.hasTerminal = inputIsTerminal;
        output.hasTerminal = !inputIsTerminal;
        await expectLater(
          confirm(),
          throwsA(isA<AscKeyConfirmationException>()),
        );
        expect(input.reads, 0);
        expect(output.messages, isEmpty);
      },
    );
  }

  for (final error in [
    const StdinException('private diagnostic'),
    const FormatException('private diagnostic'),
  ]) {
    test('wraps an input failure: ${error.runtimeType}', () async {
      input.error = error;
      await expectLater(confirm(), throwsA(isA<AscKeyConfirmationException>()));
    });
  }

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    test('asks only about saving when reusing a key: $locale', () async {
      LocaleSettings.setLocaleSync(locale);
      input.line = 'yes';
      expect(await confirmAscKeySave(input: input, output: output), isTrue);
      expect(output.messages, [t.setup.ascKeys.confirmKeySave]);
      expect(input.reads, 1);
    });
  }
}
