import 'dart:convert';
import 'dart:io';

import 'package:genuineci_cli/src/i18n/i18n.dart';
import 'package:genuineci_cli/src/update/prompt_for_update.dart';
import 'package:test/test.dart';

class _Input implements Stdin {
  _Input(this.answer, {this.invalidEncoding = false});

  final String? answer;
  final bool invalidEncoding;

  @override
  String? readLineSync({
    Encoding encoding = systemEncoding,
    bool retainNewlines = false,
  }) {
    if (invalidEncoding) throw const FormatException('invalid UTF-8');
    return answer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Output implements Stdout {
  final text = StringBuffer();

  @override
  void write(Object? object) => text.write(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppLocale originalLocale;

  setUp(() {
    originalLocale = LocaleSettings.currentLocale;
  });

  tearDown(() => LocaleSettings.setLocaleSync(originalLocale));

  for (final locale in AppLocale.values) {
    for (final answer in [
      'y',
      'yes',
      'Y',
      ' YES ',
      '',
      'n',
      'no',
      'other',
      null,
    ]) {
      test('confirms only an explicit yes: $locale / $answer', () {
        LocaleSettings.setLocaleSync(locale);
        final output = _Output();

        expect(
          promptForUpdate(input: _Input(answer), output: output),
          ['y', 'yes', 'Y', ' YES '].contains(answer),
        );
        expect(output.text.toString(), '${t.update.confirm} [y/N] ');
      });
    }
  }

  test('declines malformed input', () {
    expect(
      promptForUpdate(
        input: _Input(null, invalidEncoding: true),
        output: _Output(),
      ),
      isFalse,
    );
  });
}
