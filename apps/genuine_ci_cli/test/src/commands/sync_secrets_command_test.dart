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
  group('sync secrets', () {
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
      tempHome = Directory.systemTemp.createTempSync('genuineci_sync_test_');
      tempWorkDir = Directory.systemTemp.createTempSync('genuineci_sync_work_');

      configStorage =
          ConfigStorage(
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

    test('fetches secrets and generates secrets.g.dart successfully', () async {
      when(() => mockApiService.getSecrets('team-123')).thenAnswer(
        (_) async => chopper.Response(
          http.Response('', 200),
          const {
            'success': true,
            'secrets': [
              {'name': 'SLACK_WEBHOOK_URL'},
              {'name': 'APP_STORE_CONNECT_KEY'},
            ],
          },
        ),
      );

      final outputPath = p.join(
        tempWorkDir.path,
        'genuine_ci',
        'secrets.g.dart',
      );

      final exitCode = await commandRunner.run([
        'sync',
        'secrets',
        '--output',
        outputPath,
      ]);

      expect(exitCode, ExitCode.success.code);

      final generatedFile = File(outputPath);
      expect(generatedFile.existsSync(), isTrue);

      final content = generatedFile.readAsStringSync();
      expect(content, contains('static String get slackWebhookUrl =>'));
      expect(content, contains('static String get appStoreConnectKey =>'));

      verify(() => progress.complete(any())).called(1);
      verify(() => logger.success(any())).called(1);
    });

    test('returns usage code if team-id is not specified', () async {
      configStorage.saveGlobalConfig(
        const CliConfig(
          token: 'test-token',
        ),
      );

      final exitCode = await commandRunner.run(['sync', 'secrets']);
      expect(exitCode, ExitCode.usage.code);
      verify(() => logger.err(any())).called(1);
    });
  });
}
