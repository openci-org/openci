import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/openci_cli.dart';
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
  const token = 'private-list-token';
  const privateValue = 'private-secret-value';
  const profile = AuthProfile(
    serverUrl: 'https://ci.example.com/proxy/',
    token: token,
    teamId: 'selected/team',
  );
  late Directory root;
  late CredentialStore store;
  late _RecordingLogger logger;
  late List<http.Request> requests;
  late List<_TrackingClient> clients;
  late MockClientHandler handler;

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
    root = await Directory.systemTemp.createTemp('openci-list-secrets-');
    store = CredentialStore(
      customFilePath: p.join(root.path, 'credentials.json'),
    );
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
    handler = (_) async =>
        namesResponse(['FIREBASE_OPTIONS_DART_BASE64', 'ASC_KEY']);
  });

  tearDown(() async {
    final messages = [...logger.output, ...logger.errors].join('\n');
    expect(messages, isNot(contains(token)));
    expect(messages, isNot(contains(privateValue)));
    expect(clients.every((client) => client.closed), isTrue);
    await root.delete(recursive: true);
  });

  Future<int?> run([List<String> arguments = const []]) {
    final runner = CommandRunner<int>('openci list', 'test')
      ..addCommand(ListSecretsCommand(logger: logger, credentialStore: store));
    return http.runWithClient(() => runner.run(['secrets', ...arguments]), () {
      final client = _TrackingClient((request) async {
        requests.add(request);
        return handler(request);
      });
      clients.add(client);
      return client;
    });
  }

  test(
    'prints sorted names using the active profile without writing files',
    () async {
      final credentials = await File(store.filePath).readAsBytes();

      expect(await run(), 0);

      final request = requests.single;
      expect(request.method, 'GET');
      expect(
        request.url.toString(),
        'https://ci.example.com/proxy/teams/selected%2Fteam/secrets',
      );
      expect(request.headers['authorization'], 'Bearer $token');
      expect(request.body, isEmpty);
      expect(logger.output, ['ASC_KEY', 'FIREBASE_OPTIONS_DART_BASE64']);
      expect(logger.errors, isEmpty);
      expect(await File(store.filePath).readAsBytes(), credentials);
      expect(root.listSync().map((entry) => p.basename(entry.path)), [
        'credentials.json',
      ]);
    },
  );

  test('reports an empty team successfully', () async {
    handler = (_) async => namesResponse([]);

    expect(await run(), 0);
    expect(logger.output, [t.list.secrets.empty]);
    expect(logger.errors, isEmpty);
  });

  test('preserves legacy names and escapes terminal controls', () async {
    handler = (_) async =>
        namesResponse(['日本語のキー', 'my-key', 'A\nB', 'C\x1b[2J']);

    expect(await run(), 0);
    expect(logger.output, [r'A\x0aB', r'C\x1b[2J', 'my-key', '日本語のキー']);
  });

  test('refreshes Firebase authentication before requesting names', () async {
    await store.saveProfile(
      'selected',
      profile.copyWith(
        authType: 'firebase',
        firebaseApiKey: 'test-api-key',
        refreshToken: 'private-refresh-token',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      ),
    );
    handler = (request) async {
      if (request.url.host == 'securetoken.googleapis.com') {
        return http.Response(
          jsonEncode({
            'id_token': 'new-id-token',
            'refresh_token': 'rotated-refresh-token',
            'expires_in': '3600',
          }),
          200,
        );
      }
      expect(request.headers['authorization'], 'Bearer new-id-token');
      return namesResponse(['ASC_KEY']);
    };

    expect(await run(), 0);
    expect(requests, hasLength(2));
    expect(logger.output, ['ASC_KEY']);
    expect((await store.getActiveProfile())!.token, 'new-id-token');
  });

  test('requires login when credentials have not been saved', () async {
    await File(store.filePath).delete();

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.list.secrets.loginRequired]);
  });

  for (final (label, invalidProfile) in <(String, AuthProfile?)>[
    ('missing active profile', null),
    ('empty token', profile.copyWith(token: ' ')),
    ('empty team', profile.copyWith(teamId: ' ')),
    ('relative URL', profile.copyWith(serverUrl: '/server')),
    ('unsupported protocol', profile.copyWith(serverUrl: 'ftp://example.com')),
    (
      'URL credentials',
      profile.copyWith(serverUrl: 'https://user:password@example.com'),
    ),
    (
      'URL query',
      profile.copyWith(serverUrl: 'https://example.com/?token=$token'),
    ),
    (
      'URL fragment',
      profile.copyWith(serverUrl: 'https://example.com/#fragment'),
    ),
  ]) {
    test('requires login for $label', () async {
      await store.set(
        CredentialConfig(
          activeProfile: 'selected',
          profiles: {'selected': ?invalidProfile},
        ),
      );

      expect(await run(), 1);
      expect(clients, isEmpty);
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.list.secrets.loginRequired]);
    });
  }

  test('does not expose errors from malformed credentials', () async {
    await File(store.filePath).writeAsString(token);

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.list.secrets.loginRequired]);
  });

  test('rejects positional arguments before reading credentials', () async {
    await expectLater(run(['unexpected']), throwsA(isA<UsageException>()));
    expect(clients, isEmpty);
  });

  test('help does not read credentials or request secrets', () async {
    await File(store.filePath).writeAsString(token);

    expect(await run(['--help']), isNull);
    expect(clients, isEmpty);
    expect(logger.errors, isEmpty);
  });

  for (final status in [401, 403, 500]) {
    test('reports HTTP $status without exposing the response body', () async {
      handler = (_) async => http.Response(privateValue, status);

      expect(await run(), 1);
      expect(logger.output, isEmpty);
      expect(logger.errors, [
        status == 401 || status == 403
            ? t.list.secrets.loginRequired
            : t.list.secrets.requestFailed(status: status),
      ]);
    });
  }

  test('does not print a partial list when the response is invalid', () async {
    handler = (_) async => http.Response(
      jsonEncode({
        'success': true,
        'secrets': [
          {'name': 'ASC_KEY'},
          {'name': null, 'encryptedValue': privateValue},
        ],
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.list.secrets.fetchFailed]);
  });

  test('handles network failures without exposing exception details', () async {
    handler = (_) async => throw http.ClientException(privateValue);

    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.list.secrets.fetchFailed]);
  });
}
