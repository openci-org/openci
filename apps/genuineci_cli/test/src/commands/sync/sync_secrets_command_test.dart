import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

class _TrackingClient extends MockClient {
  _TrackingClient(super.fn);

  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  const token = 'private-test-api-key';
  const privateValue = 'private-value-must-not-be-saved';
  const previousSource = '// Previous secret definitions\n';
  const profile = AuthProfile(token: token, teamId: 'selected-team');
  late Directory project;
  late Directory workflows;
  late File output;
  late CredentialStore store;
  late _RecordingLogger logger;
  late MockClientHandler handler;
  late List<http.Request> requests;
  late List<_TrackingClient> clients;

  http.Response namesResponse(List<String> names) => http.Response(
    jsonEncode({
      'success': true,
      'secrets': [
        for (final name in names)
          {'name': name, 'encryptedValue': privateValue},
      ],
    }),
    200,
    headers: {'content-type': 'application/json'},
  );

  setUp(() async {
    project = await Directory.systemTemp.createTemp('genuineci-sync-test-');
    workflows = await Directory('${project.path}/openci').create();
    output = File('${workflows.path}/secrets.g.dart');
    await output.writeAsString(previousSource);
    store = CredentialStore(customFilePath: '${project.path}/credentials.json');
    await store.set(
      const CredentialConfig(
        activeProfile: 'selected',
        profiles: {
          'selected': profile,
          'unused': AuthProfile(token: 'unused-token', teamId: 'unused-team'),
        },
      ),
    );
    logger = _RecordingLogger();
    requests = [];
    clients = [];
    handler = (_) async => namesResponse(['ASC_KEY', 'FIREBASE_OPTIONS']);
  });

  tearDown(() async {
    final messages = [
      ...logger.stdoutMessages,
      ...logger.stderrMessages,
    ].join('\n');
    expect(messages, isNot(contains(token)));
    expect(messages, isNot(contains(privateValue)));
    expect(clients.every((client) => client.closed), isTrue);
    await project.delete(recursive: true);
  });

  Future<int?> runSync({
    List<String> arguments = const [],
    Directory? workingDirectory,
  }) async {
    final credentials = File(store.filePath);
    final previousCredentials = await credentials.exists()
        ? await credentials.readAsBytes()
        : null;
    final runner = CommandRunner<int>('genuineci sync', 'test')
      ..addCommand(
        SyncSecretsCommand(
          logger: logger,
          credentialStore: store,
          workingDirectory: workingDirectory ?? project,
        ),
      );
    try {
      return await http.runWithClient(
        () => runner.run(['secrets', ...arguments]),
        () {
          final client = _TrackingClient((request) async {
            requests.add(request);
            return handler(request);
          });
          clients.add(client);
          return client;
        },
      );
    } finally {
      if (previousCredentials == null) {
        expect(await credentials.exists(), isFalse);
      } else {
        expect(await credentials.readAsBytes(), previousCredentials);
      }
    }
  }

  Future<void> expectUnchanged(String message) async {
    expect(await output.readAsString(), previousSource);
    expect(logger.stdoutMessages, isEmpty);
    expect(logger.stderrMessages, [message]);
  }

  test('refreshes a remote session before fetching secret names', () async {
    await store.saveProfile(
      'remote',
      AuthProfile(
        serverUrl: 'https://ci.example.com',
        token: 'expired-id-token',
        teamId: 'remote-team',
        authType: 'firebase',
        refreshToken: 'private-refresh-token',
        firebaseApiKey: 'firebase-api-key',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      ),
    );
    final runner = CommandRunner<int>('genuineci sync', 'test')
      ..addCommand(
        SyncSecretsCommand(
          logger: logger,
          credentialStore: store,
          workingDirectory: project,
        ),
      );

    final result = await http.runWithClient(() => runner.run(['secrets']), () {
      final client = _TrackingClient((request) async {
        requests.add(request);
        if (request.url.host == 'securetoken.googleapis.com') {
          return http.Response(
            jsonEncode({
              'id_token': 'refreshed-id-token',
              'refresh_token': 'rotated-refresh-token',
              'expires_in': '3600',
            }),
            200,
          );
        }
        expect(
          request.url.toString(),
          'https://ci.example.com/teams/remote-team/secrets',
        );
        expect(request.headers['authorization'], 'Bearer refreshed-id-token');
        return namesResponse(['ASC_KEY']);
      });
      clients.add(client);
      return client;
    });

    expect(result, 0);
    expect(requests, hasLength(2));
    expect((await store.getActiveProfile())!.token, 'refreshed-id-token');
    final source = await output.readAsString();
    expect(source, contains("Platform.environment['ASC_KEY']"));
    for (final secret in [
      'refreshed-id-token',
      'private-refresh-token',
      'rotated-refresh-token',
    ]) {
      expect(source, isNot(contains(secret)));
      expect(
        [...logger.stdoutMessages, ...logger.stderrMessages].join('\n'),
        isNot(contains(secret)),
      );
    }
  });

  test(
    'creates definitions using the active profile and names-only API',
    () async {
      await output.delete();

      expect(await runSync(), 0);

      final request = requests.single;
      expect(request.method, 'GET');
      expect(
        request.url,
        Uri.parse('http://localhost:8080/teams/selected-team/secrets'),
      );
      expect(request.headers['Authorization'], 'Bearer $token');
      final source = await output.readAsString();
      expect(source, contains("static String get ascKey"));
      expect(source, contains("Platform.environment['ASC_KEY']"));
      expect(source, contains("static String get firebaseOptions"));
      expect(source, contains("Platform.environment['FIREBASE_OPTIONS']"));
      expect(source, isNot(contains(privateValue)));
      expect(source, isNot(contains(token)));
      expect(logger.stdoutMessages, [t.sync.secrets.saved(path: output.path)]);
      expect(logger.stderrMessages, isEmpty);
    },
  );

  test(
    'replaces definitions from a nested directory and is repeatable',
    () async {
      final nested = await Directory(
        '${project.path}/apps/example',
      ).create(recursive: true);
      await File('${workflows.path}/ci.dart').writeAsString('// Workflow\n');

      expect(await runSync(workingDirectory: nested), 0);
      final firstSource = await output.readAsString();
      handler = (_) async => namesResponse(['FIREBASE_OPTIONS', 'ASC_KEY']);
      expect(await runSync(workingDirectory: workflows), 0);

      expect(await output.readAsString(), firstSource);
      expect(
        await File('${workflows.path}/ci.dart').readAsString(),
        '// Workflow\n',
      );
      expect(clients, hasLength(2));
    },
  );

  test('removes stale getters when the team has no secrets', () async {
    handler = (_) async => namesResponse([]);

    expect(await runSync(), 0);

    final source = await output.readAsString();
    expect(source, contains('abstract final class Secrets {}'));
    expect(source, isNot(contains(previousSource)));
    expect(source, isNot(contains('Platform.environment')));
  });

  test('requires login when credentials have not been saved', () async {
    await File(store.filePath).delete();

    expect(await runSync(), 1);

    expect(clients, isEmpty);
    await expectUnchanged(t.sync.secrets.loginRequired);
  });

  for (final (label, invalidProfile) in <(String, AuthProfile?)>[
    ('missing active profile', null),
    ('missing token', const AuthProfile(teamId: 'selected-team')),
    ('missing team', const AuthProfile(token: token)),
    ('invalid server URL', profile.copyWith(serverUrl: 'http://[')),
    ('relative server URL', profile.copyWith(serverUrl: '/server')),
    (
      'unsupported server protocol',
      profile.copyWith(serverUrl: 'ftp://example.com'),
    ),
  ]) {
    test('preserves definitions for $label', () async {
      await store.set(
        CredentialConfig(
          activeProfile: 'selected',
          profiles: {'selected': ?invalidProfile},
        ),
      );

      expect(await runSync(), 1);

      expect(clients, isEmpty);
      await expectUnchanged(t.sync.secrets.loginRequired);
    });
  }

  test('does not disclose malformed credential contents', () async {
    await File(store.filePath).writeAsString('invalid credentials: $token');

    expect(await runSync(), 1);

    expect(clients, isEmpty);
    await expectUnchanged(t.sync.secrets.loginRequired);
  });

  test('requires a workflow directory before calling the API', () async {
    await workflows.delete(recursive: true);

    expect(await runSync(), 1);

    expect(clients, isEmpty);
    expect(await workflows.exists(), isFalse);
    expect(logger.stderrMessages, [t.sync.secrets.workflowDirectoryNotFound]);
  });

  for (final status in [401, 403, 404, 500]) {
    test('preserves definitions on HTTP $status', () async {
      handler = (_) async => http.Response(privateValue, status);

      expect(await runSync(), 1);

      await expectUnchanged(
        status == 401 || status == 403
            ? t.sync.secrets.loginRequired
            : t.sync.secrets.requestFailed(status: status),
      );
    });
  }

  for (final body in [
    'invalid JSON: $privateValue',
    '[]',
    '{"success":true,"secrets":[{}]}',
  ]) {
    test('preserves definitions for an invalid API response: $body', () async {
      handler = (_) async => http.Response(
        body,
        200,
        headers: {'content-type': 'application/json'},
      );

      expect(await runSync(), 1);

      await expectUnchanged(t.sync.secrets.fetchFailed);
    });
  }

  for (final error in [
    http.ClientException(privateValue),
    TimeoutException(privateValue),
  ]) {
    test(
      'preserves definitions when fetching throws ${error.runtimeType}',
      () async {
        handler = (_) async => throw error;

        expect(await runSync(), 1);

        await expectUnchanged(t.sync.secrets.fetchFailed);
      },
    );
  }

  for (final (names, message) in [
    (['INVALID-KEY'], 'Invalid secret name'),
    (['API_KEY', 'apiKey'], 'both map to Secrets.apiKey'),
  ]) {
    test('preserves definitions when generation fails for $names', () async {
      handler = (_) async => namesResponse(names);

      expect(await runSync(), 1);

      expect(await output.readAsString(), previousSource);
      expect(logger.stdoutMessages, isEmpty);
      expect(logger.stderrMessages.single, contains(message));
    });
  }

  test('reports a write failure and removes temporary files', () async {
    await output.delete();
    await Directory(output.path).create();
    final existing = File('${output.path}/keep.txt');
    await existing.writeAsString('keep');

    expect(await runSync(), 1);

    expect(await existing.readAsString(), 'keep');
    expect(workflows.listSync().map((entry) => entry.path), [output.path]);
    expect(logger.stdoutMessages, isEmpty);
    expect(logger.stderrMessages, [t.sync.secrets.saveFailed]);
  });

  test(
    'help describes generation without reading credentials or fetching',
    () async {
      await File(store.filePath).writeAsString('invalid credentials: $token');
      final messages = <String>[];

      await runZoned(
        () => runSync(arguments: ['--help']),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, message) => messages.add(message),
        ),
      );

      expect(messages.join('\n'), contains(t.sync.secrets.description));
      expect(clients, isEmpty);
      expect(logger.stderrMessages, isEmpty);
      expect(await output.readAsString(), previousSource);
    },
  );

  for (final arguments in [
    ['unexpected'],
    ['--team-id', 'other-team'],
  ]) {
    test('rejects unsupported arguments: $arguments', () async {
      await expectLater(
        runSync(arguments: arguments),
        throwsA(isA<UsageException>()),
      );

      expect(clients, isEmpty);
      expect(await output.readAsString(), previousSource);
    });
  }
}
