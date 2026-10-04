import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:genuineci_cli/src/update/cli_updater.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _Process implements Process {
  _Process(this.code);

  final int code;

  @override
  Future<int> get exitCode async => code;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Logger implements Logger {
  final output = <String>[];
  final errors = <String>[];

  @override
  void stdout(String message) => output.add(message);

  @override
  void stderr(String message) => errors.add(message);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Logger logger;
  late CommandRunner<int> runner;
  late AppLocale originalLocale;
  var latest = '0.2.0';
  var status = 200;
  var checks = 0;
  var installs = 0;
  var installExitCode = 0;

  setUp(() {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    latest = '0.2.0';
    status = 200;
    checks = 0;
    installs = 0;
    installExitCode = 0;
    logger = _Logger();
    runner = CommandRunner<int>('genuineci', 'test')
      ..addCommand(
        UpdateCommand(
          logger: logger,
          updater: CliUpdater(
            currentVersion: '0.1.0',
            clientFactory: () => MockClient((_) async {
              checks++;
              return http.Response(
                jsonEncode({
                  'name': 'genuineci_cli',
                  'latest': {'version': latest},
                }),
                status,
              );
            }),
            processStarter:
                (
                  executable,
                  arguments, {
                  required runInShell,
                  required mode,
                }) async {
                  installs++;
                  expect(arguments, ['install', 'genuineci_cli', latest]);
                  return _Process(installExitCode);
                },
          ),
        ),
      );
  });

  tearDown(() => LocaleSettings.setLocaleSync(originalLocale));

  for (final locale in AppLocale.values) {
    test('installs a newer version without confirmation: $locale', () async {
      LocaleSettings.setLocaleSync(locale);

      expect(await runner.run(['update']), 0);
      expect(checks, 1);
      expect(installs, 1);
      expect(logger.output, [
        t.update.updating(version: latest),
        t.update.updated(version: latest),
      ]);
      expect(logger.errors, isEmpty);
    });
  }

  for (final version in ['0.1.0', '0.0.3']) {
    test('does not reinstall or downgrade from the current version', () async {
      latest = version;

      expect(await runner.run(['update']), 0);
      expect(installs, 0);
      expect(logger.output, [t.update.upToDate(version: '0.1.0')]);
      expect(logger.errors, isEmpty);
    });
  }

  test('reports a failed check and does not install', () async {
    status = 503;

    expect(await runner.run(['update']), 1);
    expect(installs, 0);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.update.checkFailed]);
  });

  test('preserves installation failures', () async {
    installExitCode = 65;

    expect(await runner.run(['update']), 65);
    expect(logger.output, [t.update.updating(version: latest)]);
    expect(logger.errors, [t.update.installFailed]);
  });

  test('rejects positional arguments before checking or installing', () async {
    await expectLater(
      runner.run(['update', 'unexpected']),
      throwsA(isA<UsageException>()),
    );
    expect(checks, 0);
    expect(installs, 0);
  });
}
