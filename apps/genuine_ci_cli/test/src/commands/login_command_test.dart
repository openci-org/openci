import 'dart:io';

import 'package:genuine_ci_cli/src/command_runner.dart';
import 'package:genuine_ci_cli/src/config/config_storage.dart';
import 'package:genuine_ci_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

void main() {
  group('login', () {
    late Logger logger;
    late _MockPubUpdater pubUpdater;
    late Directory tempHome;
    late Directory tempWorkDir;
    late ConfigStorage configStorage;
    late GenuineCiCliCommandRunner commandRunner;

    setUp(() {
      logger = _MockLogger();
      pubUpdater = _MockPubUpdater();
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      tempHome = Directory.systemTemp.createTempSync(
        'genuineci_login_test_',
      );
      tempWorkDir = Directory.systemTemp.createTempSync(
        'genuineci_login_work_',
      );

      configStorage = ConfigStorage(
        homeDir: tempHome.path,
        workingDirectory: tempWorkDir.path,
      );

      commandRunner = GenuineCiCliCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
        configStorage: configStorage,
      );
    });

    tearDown(() {
      if (tempHome.existsSync()) tempHome.deleteSync(recursive: true);
      if (tempWorkDir.existsSync()) tempWorkDir.deleteSync(recursive: true);
    });

    test('saves configuration when options are provided', () async {
      final exitCode = await commandRunner.run([
        'login',
        '--server-url',
        'https://custom.openci.io',
        '--token',
        'secret_token_123',
        '--team-id',
        'team_xyz',
      ]);

      expect(exitCode, ExitCode.success.code);

      final saved = configStorage.loadGlobalConfig();
      expect(saved.serverUrl, 'https://custom.openci.io');
      expect(saved.token, 'secret_token_123');
      expect(saved.teamId, 'team_xyz');

      verify(() => logger.success('Logged in successfully!')).called(1);
      verify(() => logger.info('Server URL: https://custom.openci.io')).called(1);
      verify(() => logger.info('Team ID: team_xyz')).called(1);
    });

    test('prompts for token and teamId when not provided', () async {
      when(
        () => logger.prompt('Enter OpenCI API Token or Key:'),
      ).thenReturn('prompted_token');

      when(
        () => logger.prompt(
          'Enter Team ID (optional, press Enter to skip):',
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn('prompted_team');

      final exitCode = await commandRunner.run(['login']);

      expect(exitCode, ExitCode.success.code);

      final saved = configStorage.loadGlobalConfig();
      expect(saved.token, 'prompted_token');
      expect(saved.teamId, 'prompted_team');

      verify(() => logger.success('Logged in successfully!')).called(1);
    });

    test('returns usage code when token is empty', () async {
      when(
        () => logger.prompt('Enter OpenCI API Token or Key:'),
      ).thenReturn('');

      final exitCode = await commandRunner.run(['login']);

      expect(exitCode, ExitCode.usage.code);
      verify(() => logger.err('Token cannot be empty.')).called(1);
    });
  });
}
