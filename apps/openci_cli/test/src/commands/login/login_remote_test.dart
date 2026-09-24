import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/src/auth/firebase_auth_client.dart';
import 'package:openci_cli/src/commands/login/read_login_credentials.dart';
import 'package:openci_cli/src/commands/login_command.dart';
import 'package:openci_cli/src/credential_store/credential_config.dart';
import 'package:openci_cli/src/credential_store/credential_store.dart';
import 'package:openci_cli/src/i18n/i18n.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _RecordingLogger implements Logger {
  final messages = <String>[];
  @override
  void stdout(String message) => messages.add(message);
  @override
  void stderr(String message) => messages.add(message);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const password = 'private-password';
  const token = 'private-id-token';
  const refreshToken = 'private-refresh-token';
  late Directory temp;
  late CredentialStore store;
  late _RecordingLogger logger;
  late List<http.Request> requests;
  late MockClientHandler handler;
  late LoginCredentials? credentials;
  late int prompts;
  late String before;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('openci-remote-login-test-');
    store = CredentialStore(customFilePath: '${temp.path}/credentials.json');
    await store.saveProfile(
      'local',
      const AuthProfile(token: 'local-key', teamId: 'test-team'),
    );
    before = await File(store.filePath).readAsString();
    logger = _RecordingLogger();
    requests = [];
    credentials = (email: 'user@example.com', password: password);
    prompts = 0;
    handler = (request) async =>
        request.url.host == 'identitytoolkit.googleapis.com'
        ? http.Response(
            jsonEncode({
              'idToken': token,
              'refreshToken': refreshToken,
              'expiresIn': '3600',
            }),
            200,
          )
        : http.Response('[{"id":"team-1","name":"My team"}]', 200);
  });

  tearDown(() async {
    for (final secret in [password, token, refreshToken]) {
      expect(logger.messages.join('\n'), isNot(contains(secret)));
    }
    await temp.delete(recursive: true);
  });

  Future<int?> runLogin([List<String> options = const []]) {
    final runner = CommandRunner<int>('openci', 'test')
      ..addCommand(
        LoginCommand(
          logger: logger,
          credentialStore: store,
          processRunner: (_, _) async =>
              throw StateError('Remote login must not use Docker'),
          readCredentials: () async {
            prompts++;
            return credentials;
          },
          client: MockClient((request) async {
            requests.add(request);
            return handler(request);
          }),
        ),
      );
    return runner.run(['login', ...options]);
  }

  test(
    'logs in to the default server and activates the remote profile without options',
    () async {
      expect(await runLogin(), 0);

      expect(prompts, 1);
      expect(requests, hasLength(2));
      expect(requests.first.url.queryParameters['key'], defaultFirebaseApiKey);
      expect(jsonDecode(requests.first.body)['password'], password);
      final teamRequest = requests.last;
      expect(teamRequest.method, 'GET');
      expect(
        teamRequest.url.toString(),
        'https://openci-worker-01.tail4beb18.ts.net/teams',
      );
      expect(teamRequest.headers['Authorization'], 'Bearer $token');
      expect(teamRequest.followRedirects, isFalse);
      expect(teamRequest.body, isEmpty);
      final saved = await store.get();
      expect(saved.activeProfile, 'remote');
      expect(saved.profiles['local']!.token, 'local-key');
      final remote = saved.profiles['remote']!;
      expect(remote.serverUrl, 'https://openci-worker-01.tail4beb18.ts.net');
      expect(remote.teamId, 'team-1');
      expect(remote.authType, 'firebase');
      expect(remote.token, token);
      expect(remote.refreshToken, refreshToken);
      expect(remote.firebaseApiKey, defaultFirebaseApiKey);
      expect(remote.expiresAt!.isAfter(DateTime.now().toUtc()), isTrue);
      expect(
        await File(store.filePath).readAsString(),
        isNot(contains(password)),
      );
      if (!Platform.isWindows) {
        expect((await File(store.filePath).stat()).mode & 0x1ff, 0x180);
      }
    },
  );

  test(
    'supports a custom server, Firebase project and explicit team',
    () async {
      final defaultHandler = handler;
      handler = (request) =>
          request.url.host == 'identitytoolkit.googleapis.com'
          ? defaultHandler(request)
          : Future.value(
              http.Response('[{"id":"team-1"},{"id":"team-2"}]', 200),
            );

      expect(
        await runLogin([
          '--server',
          'https://ci.example.com/proxy/',
          '--team-id',
          'team-2',
          '--firebase-api-key',
          'self-hosted-key',
        ]),
        0,
      );

      expect(requests.first.url.queryParameters['key'], 'self-hosted-key');
      expect(
        requests.last.url.toString(),
        'https://ci.example.com/proxy/teams',
      );
      final saved = await store.getActiveProfile();
      expect(saved!.serverUrl, 'https://ci.example.com/proxy');
      expect(saved.teamId, 'team-2');
      expect(saved.firebaseApiKey, 'self-hosted-key');
    },
  );

  for (final (body, message) in [
    ('[]', () => t.login.noTeams),
    ('[{"id":"team-1"},{"id":"team-2"}]', () => t.login.teamRequired),
    ('[{"id":42}]', () => t.login.invalidResponse),
    ('[{"id":""}]', () => t.login.invalidResponse),
    ('null', () => t.login.invalidResponse),
  ]) {
    test(
      'does not save credentials when team selection fails: $body',
      () async {
        final defaultHandler = handler;
        handler = (request) =>
            request.url.host == 'identitytoolkit.googleapis.com'
            ? defaultHandler(request)
            : Future.value(http.Response(body, 200));

        expect(await runLogin(), 1);
        expect(logger.messages, contains(message()));
        expect(await File(store.filePath).readAsString(), before);
      },
    );
  }

  test('rejects a team outside the authenticated membership list', () async {
    expect(
      await runLogin([
        '--server',
        'https://ci.example.com',
        '--team-id',
        'other-team',
      ]),
      1,
    );
    expect(logger.messages, contains(t.login.teamNotFound));
    expect(await File(store.filePath).readAsString(), before);
  });

  test('preserves credentials when Firebase rejects login', () async {
    handler = (_) async => http.Response(password, 400);

    expect(await runLogin(), 1);
    expect(requests, hasLength(1));
    expect(logger.messages, contains(t.login.firebaseAuthenticationFailed));
    expect(await File(store.filePath).readAsString(), before);
  });

  for (final status in [401, 403, 302, 500]) {
    test(
      'preserves credentials when the remote server returns $status',
      () async {
        final defaultHandler = handler;
        handler = (request) =>
            request.url.host == 'identitytoolkit.googleapis.com'
            ? defaultHandler(request)
            : Future.value(http.Response(token, status));

        expect(await runLogin(), 1);
        expect(
          logger.messages,
          contains(t.login.requestFailed(status: status)),
        );
        expect(await File(store.filePath).readAsString(), before);
      },
    );
  }

  test(
    'cancelling the prompt makes no requests and preserves credentials',
    () async {
      credentials = null;
      expect(await runLogin(), 1);
      expect(requests, isEmpty);
      expect(await File(store.filePath).readAsString(), before);
    },
  );

  test('does not overwrite a malformed credential file', () async {
    await File(store.filePath).writeAsString('existing malformed file');
    expect(await runLogin(), 1);
    expect(logger.messages, contains(t.login.saveFailed));
    expect(
      await File(store.filePath).readAsString(),
      'existing malformed file',
    );
  });

  for (final options in <List<String>>[
    ['--server', ''],
    ['--server', 'http://ci.example.com'],
    ['--server', 'https://user:password@ci.example.com'],
    ['--server', 'https://ci.example.com?token=secret'],
    ['--server', 'https://ci.example.com#fragment'],
    ['--server', 'https://ci.example.com', '--team-id', ''],
    ['--server', 'https://ci.example.com', '--firebase-api-key', ''],
    ['--local', '--server', 'https://ci.example.com'],
  ]) {
    test(
      'validates options before prompting or making requests: $options',
      () async {
        await expectLater(runLogin(options), throwsA(isA<UsageException>()));
        expect(prompts, 0);
        expect(requests, isEmpty);
        expect(await File(store.filePath).readAsString(), before);
      },
    );
  }
}
