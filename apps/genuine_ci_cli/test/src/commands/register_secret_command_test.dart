import 'dart:io';

import 'package:chopper/chopper.dart' as chopper;
import 'package:genuine_ci_cli/src/command_runner.dart';
import 'package:genuine_ci_cli/src/config/cli_config.dart';
import 'package:genuine_ci_cli/src/config/config_storage.dart';
import 'package:genuine_ci_cli/src/version.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:path/path.dart' as p;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _MockOpenCiApiService extends Mock implements OpenCiApiService {}

class _MockPubUpdater extends Mock implements PubUpdater {}

void main() {
  group('register secret', () {
    late Logger logger;
    late Progress progress;
    late _MockOpenCiApiService mockApiService;
    late _MockPubUpdater pubUpdater;
    late Directory tempHome;
    late Directory tempWorkDir;
    late ConfigStorage configStorage;
    late GenuineCiCliCommandRunner commandRunner;

    setUp(() {
      logger = _MockLogger();
      progress = _MockProgress();
      pubUpdater = _MockPubUpdater();
      when(() => logger.progress(any())).thenReturn(progress);
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      mockApiService = _MockOpenCiApiService();
      tempHome =
          Directory.systemTemp.createTempSync('genuineci_reg_test_');
      tempWorkDir =
          Directory.systemTemp.createTempSync('genuineci_reg_work_');

      configStorage = ConfigStorage(
        homeDir: tempHome.path,
        workingDirectory: tempWorkDir.path,
      )..saveGlobalConfig(
        const CliConfig(
          token: 'test-token',
          teamId: 'team-123',
        ),
      );

      commandRunner = GenuineCiCliCommandRunner(
        logger: logger,
        pubUpdater: pubUpdater,
        configStorage: configStorage,
        apiServiceFactory: (_) => mockApiService,
      );
    });

    tearDown(() {
      if (tempHome.existsSync()) tempHome.deleteSync(recursive: true);
      if (tempWorkDir.existsSync()) tempWorkDir.deleteSync(recursive: true);
    });

    test('registers secret and automatically syncs code', () async {
      when(
        () => mockApiService.saveSecret(
          'team-123',
          const {'name': 'FIREBASE_TOKEN', 'value': 'secret_val_123'},
        ),
      ).thenAnswer((_) async => chopper.Response(http.Response('', 200), null));

      when(() => mockApiService.getSecrets('team-123')).thenAnswer(
        (_) async => chopper.Response(
          http.Response('', 200),
          const {
            'success': true,
            'secrets': [
              {'name': 'FIREBASE_TOKEN'},
            ],
          },
        ),
      );

      final exitCode = await commandRunner.run([
        'register',
        'secret',
        '--name',
        'FIREBASE_TOKEN',
        '--value',
        'secret_val_123',
      ]);

      expect(exitCode, ExitCode.success.code);
      verify(
        () => mockApiService.saveSecret(
          'team-123',
          {'name': 'FIREBASE_TOKEN', 'value': 'secret_val_123'},
        ),
      ).called(1);
      verify(() => mockApiService.getSecrets('team-123')).called(1);
      verify(() => logger.success(any())).called(2);
    });

    test('registers secret from file with --from-file', () async {
      final secretFile = File(p.join(tempWorkDir.path, 'my_key.p8'))
        ..writeAsStringSync('-----BEGIN PRIVATE KEY-----\nMIIEvgI...\n');

      when(
        () => mockApiService.saveSecret(
          'team-123',
          {
            'name': 'AUTH_KEY_P8',
            'value': '-----BEGIN PRIVATE KEY-----\nMIIEvgI...',
          },
        ),
      ).thenAnswer((_) async => chopper.Response(http.Response('', 200), null));

      final exitCode = await commandRunner.run([
        'register',
        'secret',
        '--name',
        'AUTH_KEY_P8',
        '--from-file',
        secretFile.path,
        '--no-sync',
      ]);

      expect(exitCode, ExitCode.success.code);
      verify(
        () => mockApiService.saveSecret(
          'team-123',
          {
            'name': 'AUTH_KEY_P8',
            'value': '-----BEGIN PRIVATE KEY-----\nMIIEvgI...',
          },
        ),
      ).called(1);
      verifyNever(() => mockApiService.getSecrets(any()));
    });
  });
}
