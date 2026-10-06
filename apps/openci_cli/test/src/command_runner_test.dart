import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cli_completion/parser.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:genuineci_cli/src/update/cli_updater.dart';
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

class _Updater extends CliUpdater {
  _Updater() : super(currentVersion: '0.1.0');

  String? version = '0.2.0';
  Object? checkError;
  int checks = 0;
  final installedVersions = <String>[];
  int installExitCode = 0;

  @override
  Future<String?> getLatestUpdate({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    checks++;
    if (checkError != null) throw checkError!;
    return version;
  }

  @override
  Future<int> install(String version, Logger logger) async {
    installedVersions.add(version);
    return installExitCode;
  }
}

class _ExampleCommand extends Command<int> {
  _ExampleCommand(this.logger);

  final Logger logger;
  int runs = 0;

  @override
  String get name => 'example';

  @override
  String get description => 'A command with a distinct result.';

  @override
  int run() {
    runs++;
    logger.stdout('command output');
    return 7;
  }
}

class _CompletionRunner extends GenuineCICommandRunner {
  _CompletionRunner({
    required super.logger,
    required super.updater,
    required super.environment,
    required super.confirmUpdate,
  }) : super(hasTerminal: true);

  final suggestions = <String, String?>{};

  @override
  void renderCompletionResult(CompletionResult result) {
    suggestions.addAll(result.completions);
  }
}

void main() {
  late _RecordingLogger logger;
  late GenuineCICommandRunner runner;

  setUp(() {
    logger = _RecordingLogger();
    runner = GenuineCICommandRunner(logger: logger, hasTerminal: false);
  });

  group('version', () {
    for (final flag in ['--version', '-v']) {
      test('prints the version and returns 0 for $flag', () async {
        final result = await runner.run([flag]);

        expect(result, equals(0));
        expect(
          logger.stdoutMessages,
          equals([t.cli.version(version: genuineCIVersion)]),
        );
        expect(logger.stderrMessages, isEmpty);
      });
    }

    test('does not run a subcommand when --version is specified', () async {
      final result = await runner.run(['--version', 'use']);

      expect(result, equals(0));
      expect(
        logger.stdoutMessages,
        equals([t.cli.version(version: genuineCIVersion)]),
      );
      expect(logger.stderrMessages, isEmpty);
    });
  });

  test('registers login and use commands', () {
    expect(runner.commands['login'], isA<LoginCommand>());
    expect(runner.commands['use'], isA<UseCommand>());
  });

  test('registers status with a localized description', () {
    final status = runner.commands['status'];
    expect(status, isA<StatusCommand>());
    expect(status!.description, t.status.description);
  });

  test('registers update with a localized description', () {
    expect(runner.commands['update'], isA<UpdateCommand>());
    expect(runner.commands['update']!.description, t.update.description);
  });

  test('registers register secret with localized descriptions', () {
    final register = runner.commands['register'];
    expect(register, isA<RegisterCommand>());
    expect(register!.description, t.register.description);
    final secret = register.subcommands['secret'];
    expect(secret, isA<RegisterSecretCommand>());
    expect(secret!.description, t.register.secret.description);
    final secretFile = register.subcommands['secretFile'];
    expect(secretFile, isA<RegisterSecretFileCommand>());
    expect(secretFile!.description, t.register.secretFile.description);
  });

  test('registers setup asc-keys with localized descriptions', () {
    final setup = runner.commands['setup'];
    expect(setup, isA<SetupCommand>());
    expect(setup!.description, t.setup.description);
    final ascKeys = setup.subcommands['asc-keys'];
    expect(ascKeys, isA<SetupAscKeysCommand>());
    expect(ascKeys!.description, t.setup.ascKeys.description);
  });

  test('registers list secrets with localized descriptions', () {
    final list = runner.commands['list'];
    expect(list, isA<ListCommand>());
    expect(list!.description, t.list.description);
    final secrets = list.subcommands['secrets'];
    expect(secrets, isA<ListSecretsCommand>());
    expect(secrets!.description, t.list.secrets.description);
  });

  test('registers list teams with a localized description', () {
    final teams = runner.commands['list']!.subcommands['teams'];
    expect(teams, isA<ListTeamsCommand>());
    expect(teams!.description, t.list.teams.description);
  });

  test('registers switch team with localized descriptions', () {
    final switchCommand = runner.commands['switch'];
    expect(switchCommand, isA<SwitchCommand>());
    expect(switchCommand!.description, t.switchCommand.description);
    final team = switchCommand.subcommands['team'];
    expect(team, isA<SwitchTeamCommand>());
    expect(team!.description, t.switchCommand.team.description);
  });

  test('registers sync with localized selection flags', () {
    final sync = runner.commands['sync'];
    expect(sync, isA<SyncCommand>());
    expect(sync!.description, t.sync.description);
    expect(sync.subcommands, isEmpty);
    expect(sync.argParser.options['secrets']!.help, t.sync.secrets.description);
    expect(sync.argParser.options['paths']!.help, t.sync.paths.description);
  });

  test('login rejects a remote server URL without HTTPS', () async {
    await expectLater(
      runner.run(['login', '--server', 'http://ci.example.com']),
      throwsA(
        isA<UsageException>().having(
          (error) => error.message,
          'message',
          t.login.serverRequired,
        ),
      ),
    );
    expect(logger.stdoutMessages, isEmpty);
  });

  test('runs a subcommand and preserves its exit code and logger', () async {
    final result = await runner.run(['use']);

    expect(result, equals(64));
    expect(logger.stdoutMessages, isEmpty);
    expect(
      logger.stderrMessages,
      equals(['Usage: genuineci use <japanese|english>']),
    );
  });

  group('shell completion', () {
    for (final shell in ['bash', 'zsh']) {
      for (final (line, expected) in [
        ('genuineci ', ['login', 'register', 'switch', '--version']),
        ('genuineci reg', ['register']),
        ('genuineci register ', ['secret', 'secretFile']),
        ('genuineci switch ', ['team']),
        ('genuineci login --ser', ['--server']),
        ('genuineci --no-check', ['--no-check-updates']),
      ]) {
        test('$shell completes "$line" without checking for updates', () async {
          final updater = _Updater();
          var confirmations = 0;
          final completionRunner = _CompletionRunner(
            logger: logger,
            updater: updater,
            environment: {
              'SHELL': '/bin/$shell',
              'COMP_LINE': line,
              'COMP_POINT': '${line.length}',
              'COMP_CWORD': '${line.split(' ').length - 1}',
            },
            confirmUpdate: () {
              confirmations++;
              return true;
            },
          );

          expect(
            await completionRunner.run([
              'completion',
              '--',
              ...line.split(' '),
            ]),
            0,
          );
          expect(completionRunner.suggestions.keys, containsAll(expected));
          expect(completionRunner.suggestions, isNot(contains('completion')));
          expect(updater.checks, 0);
          expect(updater.installedVersions, isEmpty);
          expect(confirmations, 0);
          expect(logger.stdoutMessages, isEmpty);
          expect(logger.stderrMessages, isEmpty);
        });
      }
    }
  });

  group('interactive update check', () {
    late _Updater updater;
    late _ExampleCommand command;
    var confirmations = 0;
    var accept = false;

    void createRunner({
      bool hasTerminal = true,
      Map<String, String> environment = const {},
    }) {
      runner = GenuineCICommandRunner(
        logger: logger,
        updater: updater,
        hasTerminal: hasTerminal,
        environment: environment,
        confirmUpdate: () {
          confirmations++;
          return accept;
        },
      )..addCommand(command);
    }

    setUp(() {
      updater = _Updater();
      command = _ExampleCommand(logger);
      confirmations = 0;
      accept = false;
      createRunner();
    });

    test('offers a newer version and continues when declined', () async {
      expect(await runner.run(['example']), 7);

      expect(updater.checks, 1);
      expect(confirmations, 1);
      expect(updater.installedVersions, isEmpty);
      expect(command.runs, 1);
      expect(logger.stdoutMessages, ['command output']);
      expect(logger.stderrMessages, [
        t.update.available(current: updater.currentVersion, latest: '0.2.0'),
      ]);
    });

    test(
      'installs only after yes and asks to rerun with the new CLI',
      () async {
        accept = true;

        expect(await runner.run(['example']), 0);

        expect(confirmations, 1);
        expect(updater.installedVersions, ['0.2.0']);
        expect(command.runs, 0);
        expect(logger.stdoutMessages, isEmpty);
        expect(logger.stderrMessages.last, t.update.rerunCommand);
      },
    );

    test(
      'returns installation failure without executing the command',
      () async {
        accept = true;
        updater.installExitCode = 65;

        expect(await runner.run(['example']), 65);

        expect(command.runs, 0);
        expect(logger.stderrMessages, isNot(contains(t.update.rerunCommand)));
      },
    );

    test('does not prompt when no update is available', () async {
      updater.version = null;

      expect(await runner.run(['example']), 7);

      expect(confirmations, 0);
      expect(updater.installedVersions, isEmpty);
      expect(logger.stdoutMessages, ['command output']);
      expect(logger.stderrMessages, isEmpty);
    });

    for (final error in [Exception('offline'), TimeoutException('timed out')]) {
      test('silently continues after $error', () async {
        updater.checkError = error;

        expect(await runner.run(['example']), 7);

        expect(confirmations, 0);
        expect(logger.stdoutMessages, ['command output']);
        expect(logger.stderrMessages, isEmpty);
      });
    }

    test('skips checks when any standard stream is not a terminal', () async {
      createRunner(hasTerminal: false);

      expect(await runner.run(['example']), 7);
      expect(updater.checks, 0);
      expect(confirmations, 0);
    });

    for (final ciValue in ['', 'true', '1', 'false']) {
      test('skips checks whenever CI is set to "$ciValue"', () async {
        createRunner(environment: {'CI': ciValue});

        expect(await runner.run(['example']), 7);
        expect(updater.checks, 0);
        expect(confirmations, 0);
      });
    }

    test('supports opting out with --no-check-updates', () async {
      expect(await runner.run(['--no-check-updates', 'example']), 7);
      expect(updater.checks, 0);
      expect(confirmations, 0);
    });

    for (final arguments in [
      <String>[],
      ['--version'],
      ['-v', 'example'],
      ['--help'],
      ['help', 'example'],
      ['example', '--help'],
      ['switch', 'team', '--help'],
      ['update', '--help'],
    ]) {
      test('skips checks for help/version: $arguments', () async {
        await runZoned(
          () => runner.run(arguments),
          zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
        );

        expect(updater.checks, 0);
        expect(confirmations, 0);
        expect(command.runs, 0);
      });
    }

    test(
      'manual update checks once without prompting, including in CI',
      () async {
        createRunner(hasTerminal: false, environment: {'CI': 'true'});

        expect(await runner.run(['--no-check-updates', 'update']), 0);

        expect(updater.checks, 1);
        expect(updater.installedVersions, ['0.2.0']);
        expect(confirmations, 0);
      },
    );
  });
}
