import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _RecordingLogger implements Logger {
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
  late Directory root;
  late Directory workflows;
  late File pubspec;
  late File paths;
  late File secrets;
  late CredentialStore store;
  late _RecordingLogger logger;
  late List<http.Request> requests;
  late int status;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('genuineci-sync-');
    workflows = await Directory(p.join(root.path, 'openci')).create();
    await Directory(p.join(root.path, 'lib')).create();
    pubspec = File(p.join(root.path, 'pubspec.yaml'));
    await pubspec.writeAsString('name: example\n');
    paths = File(p.join(workflows.path, 'generated', 'paths.g.dart'));
    secrets = File(p.join(workflows.path, 'generated', 'secrets.g.dart'));
    store = CredentialStore(
      customFilePath: p.join(root.path, 'credentials.json'),
    );
    await store.saveProfile(
      'test',
      const AuthProfile(token: 'private-token', teamId: 'selected-team'),
    );
    logger = _RecordingLogger();
    requests = [];
    status = 200;
  });

  tearDown(() => root.delete(recursive: true));

  Future<int?> runSync([List<String> arguments = const []]) {
    final runner = CommandRunner<int>('genuineci', 'test')
      ..addCommand(
        SyncCommand(
          logger: logger,
          credentialStore: store,
          workingDirectory: workflows,
        ),
      );
    return http.runWithClient(
      () => runner.run(['sync', ...arguments]),
      () => MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'success': true,
            'secrets': [
              {'name': 'API_KEY'},
            ],
          }),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  }

  for (final (arguments, generatePaths, generateSecrets) in [
    (<String>[], true, true),
    (['--paths'], true, false),
    (['--secrets'], false, true),
    (['--paths', '--secrets'], true, true),
    (['--secrets', '--paths'], true, true),
  ]) {
    test('generates only the selected files for sync $arguments', () async {
      const previous = '// Keep unselected definitions\n';
      if (!generateSecrets) {
        await secrets.parent.create();
        await secrets.writeAsString(previous);
        await File(store.filePath).writeAsString('invalid credentials');
      }
      if (!generatePaths) {
        await paths.parent.create();
        await paths.writeAsString(previous);
        await pubspec.delete();
      }

      expect(await runSync(arguments), 0);

      expect(
        await paths.readAsString(),
        generatePaths ? contains('WorkspaceDirectory("lib")') : previous,
      );
      expect(
        await secrets.readAsString(),
        generateSecrets
            ? contains("Platform.environment['API_KEY']")
            : previous,
      );
      expect(requests, hasLength(generateSecrets ? 1 : 0));
      expect(
        logger.output,
        hasLength((generatePaths ? 1 : 0) + (generateSecrets ? 1 : 0)),
      );
      expect(logger.errors, isEmpty);
      expect(
        await File(p.join(workflows.path, 'paths.g.dart')).exists(),
        isFalse,
      );
      expect(
        await File(p.join(workflows.path, 'secrets.g.dart')).exists(),
        isFalse,
      );
    });
  }

  test('default generation creates the directory and is repeatable', () async {
    expect(await paths.parent.exists(), isFalse);

    expect(await runSync(), 0);
    final firstPaths = await paths.readAsString();
    final firstSecrets = await secrets.readAsString();
    expect(await runSync(), 0);

    expect(await paths.readAsString(), firstPaths);
    expect(await secrets.readAsString(), firstSecrets);
    expect(firstPaths, isNot(contains('get generated')));
    expect(requests, hasLength(2));
  });

  test(
    'still generates paths and fails when secrets cannot be fetched',
    () async {
      status = 500;

      expect(await runSync(), 1);

      expect(await paths.exists(), isTrue);
      expect(await secrets.exists(), isFalse);
      expect(logger.errors, [t.sync.secrets.requestFailed(status: 500)]);
    },
  );

  test('still generates paths and fails when login is missing', () async {
    await File(store.filePath).delete();

    expect(await runSync(), 1);

    expect(await paths.exists(), isTrue);
    expect(await secrets.exists(), isFalse);
    expect(requests, isEmpty);
    expect(logger.errors, [t.sync.secrets.loginRequired]);
  });

  test(
    'still generates secrets and fails when paths cannot be generated',
    () async {
      await pubspec.writeAsString('workspace: [\n');

      expect(await runSync(), 1);

      expect(await paths.exists(), isFalse);
      expect(await secrets.exists(), isTrue);
      expect(logger.errors.single, contains('invalid YAML'));
    },
  );

  test(
    'help does not read credentials, fetch secrets, or create files',
    () async {
      await File(store.filePath).writeAsString('invalid credentials');
      await pubspec.delete();
      final messages = <String>[];

      await runZoned(
        () => runSync(['--help']),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, message) => messages.add(message),
        ),
      );

      expect(messages.join('\n'), contains('--secrets'));
      expect(messages.join('\n'), contains('--paths'));
      expect(requests, isEmpty);
      expect(logger.errors, isEmpty);
      expect(await paths.parent.exists(), isFalse);
    },
  );

  for (final arguments in [
    ['paths'],
    ['secrets'],
    ['unexpected'],
    ['--no-paths'],
    ['--no-secrets'],
  ]) {
    test(
      'rejects unsupported arguments without generation: $arguments',
      () async {
        await expectLater(runSync(arguments), throwsA(isA<UsageException>()));

        expect(requests, isEmpty);
        expect(await paths.parent.exists(), isFalse);
      },
    );
  }
}
