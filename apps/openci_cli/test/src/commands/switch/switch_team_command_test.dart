import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:test/test.dart';

class _RecordingLogger implements Logger {
  final stdoutMessages = <String>[];
  final stderrMessages = <String>[];

  @override
  void stdout(String message) => stdoutMessages.add(message);

  @override
  void stderr(String message) => stderrMessages.add(message);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppLocale originalLocale;
  late _RecordingLogger logger;
  late GenuineCICommandRunner runner;

  setUp(() {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    logger = _RecordingLogger();
    runner = GenuineCICommandRunner(logger: logger);
  });

  tearDown(() => LocaleSettings.setLocaleSync(originalLocale));

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    group('$locale', () {
      setUp(() => LocaleSettings.setLocaleSync(locale));

      for (final arguments in [
        ['--help'],
        ['switch', '--help'],
        ['switch', 'team', '--help'],
      ]) {
        test('shows localized help for $arguments', () async {
          // Construct after choosing the locale so the runner's own description
          // uses the same language as its commands.
          runner = GenuineCICommandRunner(logger: logger);
          final messages = <String>[];
          final result = await runZoned(
            () => runner.run(arguments),
            zoneSpecification: ZoneSpecification(
              print: (_, _, _, message) => messages.add(message),
            ),
          );

          final help = messages.join('\n');
          expect(result, isNull);
          if (arguments.length == 1) {
            expect(help, contains(t.switchCommand.description));
            expect(help, matches(RegExp(r'^\s+switch\s+', multiLine: true)));
          } else if (arguments.length == 2) {
            expect(help, contains('Usage: genuineci switch'));
            expect(help, contains(t.switchCommand.team.description));
            expect(help, matches(RegExp(r'^\s+team\s+', multiLine: true)));
          } else {
            expect(help, contains('Usage: genuineci switch team'));
            expect(help, contains(t.switchCommand.team.description));
          }
          expect(logger.stdoutMessages, isEmpty);
          expect(logger.stderrMessages, isEmpty);
        });
      }

      for (final arguments in [
        ['unexpected'],
        ['--', 'unexpected'],
      ]) {
        test('rejects positional arguments: $arguments', () async {
          await expectLater(
            runner.run(['switch', 'team', ...arguments]),
            throwsA(
              isA<UsageException>()
                  .having(
                    (error) => error.message,
                    'message',
                    t.switchCommand.team.noArguments,
                  )
                  .having(
                    (error) => error.usage,
                    'usage',
                    contains('Usage: genuineci switch team'),
                  ),
            ),
          );
          expect(logger.stdoutMessages, isEmpty);
          expect(logger.stderrMessages, isEmpty);
        });
      }
    });
  }

  for (final arguments in [
    ['switch'],
    ['switch', 'unknown'],
    ['switch', 'teams'],
  ]) {
    test('rejects a missing or unknown subcommand: $arguments', () async {
      await expectLater(
        runner.run(arguments),
        throwsA(
          isA<UsageException>().having(
            (error) => error.usage,
            'usage',
            contains('Usage: genuineci switch'),
          ),
        ),
      );
      expect(logger.stdoutMessages, isEmpty);
      expect(logger.stderrMessages, isEmpty);
    });
  }

  test('rejects an unknown option with team command usage', () async {
    await expectLater(
      runner.run(['switch', 'team', '--unknown']),
      throwsA(
        isA<UsageException>()
            .having((error) => error.message, 'message', contains('--unknown'))
            .having(
              (error) => error.usage,
              'usage',
              contains('Usage: genuineci switch team'),
            ),
      ),
    );
    expect(logger.stdoutMessages, isEmpty);
    expect(logger.stderrMessages, isEmpty);
  });
}
