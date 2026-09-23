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
  late _RecordingLogger logger;
  late GenuineCICommandRunner runner;

  setUp(() {
    logger = _RecordingLogger();
    runner = GenuineCICommandRunner(logger: logger);
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

  test('registers list secrets with localized descriptions', () {
    final list = runner.commands['list'];
    expect(list, isA<ListCommand>());
    expect(list!.description, t.list.description);
    final secrets = list.subcommands['secrets'];
    expect(secrets, isA<ListSecretsCommand>());
    expect(secrets!.description, t.list.secrets.description);
  });

  test('registers sync secrets with localized descriptions', () {
    final sync = runner.commands['sync'];
    expect(sync, isA<SyncCommand>());
    expect(sync!.description, t.sync.description);
    expect(sync.subcommands['secrets'], isA<SyncSecretsCommand>());
    expect(
      sync.subcommands['secrets']!.description,
      t.sync.secrets.description,
    );
  });

  test('registers sync paths with a localized description', () {
    final paths = runner.commands['sync']!.subcommands['paths'];
    expect(paths, isA<SyncPathsCommand>());
    expect(paths!.description, t.sync.paths.description);
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
}
