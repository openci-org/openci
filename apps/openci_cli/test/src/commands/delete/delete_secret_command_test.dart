import '../../../helpers/secret_functions.dart';
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
  const token = 'private-delete-token';
  const privateValue = 'private-secret-value';
  const profile = AuthProfile(
    firebaseProjectId: 'test-project',
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

  http.Response success() => functionResponse(
    '{"success":true}',
    200,
    headers: {'content-type': 'application/json'},
  );

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    root = await Directory.systemTemp.createTemp('openci-delete-secret-');
    store = CredentialStore(
      customFilePath: p.join(root.path, 'credentials.json'),
    );
    await store.set(
      const CredentialConfig(
        activeProfile: 'selected',
        profiles: {
          'selected': profile,
          'unused': AuthProfile(
            firebaseProjectId: 'test-project',
            token: 'unused-token',
            teamId: 'unused-team',
          ),
        },
      ),
    );
    logger = _RecordingLogger();
    requests = [];
    clients = [];
    handler = (_) async => success();
  });

  tearDown(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    final messages = [...logger.output, ...logger.errors].join('\n');
    for (final secret in [
      token,
      privateValue,
      'private-refresh-token',
      'refreshed-id-token',
      'rotated-refresh-token',
    ]) {
      expect(messages, isNot(contains(secret)));
    }
    expect(clients.every((client) => client.closed), isTrue);
    await root.delete(recursive: true);
  });

  Future<int?> run([List<String> arguments = const ['API_TOKEN']]) {
    final runner = CommandRunner<int>('genuineci', 'test')
      ..addCommand(DeleteCommand(logger: logger, credentialStore: store));
    return http.runWithClient(
      () => runner.run(['delete', 'secret', ...arguments]),
      () {
        final client = _TrackingClient((request) async {
          requests.add(request);
          return handler(request);
        });
        clients.add(client);
        return client;
      },
    );
  }

  test('deletes only the named secret from the active team', () async {
    final credentials = await File(store.filePath).readAsBytes();

    expect(await run(), 0);

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.toString(), secretFunctionUrl);
    expect(request.headers['authorization'], 'Bearer $token');
    expect(secretData(request), {
      'action': 'delete',
      'teamId': profile.teamId,
      'name': 'API_TOKEN',
    });
    expect(logger.output, [
      t.delete.secret.deleted(name: 'API_TOKEN', teamId: profile.teamId),
    ]);
    expect(logger.errors, isEmpty);
    expect(await File(store.filePath).readAsBytes(), credentials);
    expect(root.listSync().map((entry) => p.basename(entry.path)), [
      'credentials.json',
    ]);
  });

  test('rejects a malformed empty callable response', () async {
    handler = (_) async => functionResponse('', 204);
    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, isNotEmpty);
  });

  for (final name in [
    'my-key',
    '日本語のキー',
    'name with spaces',
    '../another?key=value#fragment%2F',
  ]) {
    test('preserves the exact name in JSON: $name', () async {
      expect(await run([name]), 0);

      final request = requests.single;
      expect(request.method, 'POST');
      expect(secretData(request), {
        'action': 'delete',
        'teamId': profile.teamId,
        'name': name,
      });
      expect(request.url.hasQuery, isFalse);
      expect(request.url.hasFragment, isFalse);
    });
  }

  for (final status in [200, 404]) {
    test('escapes control characters in HTTP $status output', () async {
      await store.saveProfile(
        'selected',
        profile.copyWith(teamId: 'team\x1b[2J'),
      );
      handler = (_) async => functionResponse('{"success":true}', status);

      expect(await run(['A\nB']), status == 200 ? 0 : 1);
      expect(secretData(requests.single)['name'], 'A\nB');
      expect(
        [...logger.output, ...logger.errors],
        [
          status == 200
              ? t.delete.secret.deleted(name: r'A\x0aB', teamId: r'team\x1b[2J')
              : t.delete.secret.notFound(
                  name: r'A\x0aB',
                  teamId: r'team\x1b[2J',
                ),
        ],
      );
    });
  }

  for (final arguments in <List<String>>[
    [],
    [''],
    [' \r\n '],
    ['API_TOKEN', 'ANOTHER_TOKEN'],
    ['.'],
    ['..'],
  ]) {
    test(
      'rejects invalid arguments before reading credentials: $arguments',
      () async {
        await File(store.filePath).writeAsString(token);

        await expectLater(
          run(arguments),
          throwsA(
            isA<UsageException>().having(
              (error) => error.usage,
              'usage',
              contains('genuineci delete secret SECRET_NAME'),
            ),
          ),
        );
        expect(clients, isEmpty);
        expect(logger.output, isEmpty);
        expect(logger.errors, isEmpty);
      },
    );
  }

  test('help does not read credentials or send requests', () async {
    await File(store.filePath).writeAsString(token);

    expect(await run(['--help']), isNull);
    expect(clients, isEmpty);
    expect(logger.errors, isEmpty);
  });

  test('requires login when credentials have not been saved', () async {
    await File(store.filePath).delete();

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.delete.secret.loginRequired]);
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
    ('URL query', profile.copyWith(serverUrl: 'https://example.com/?q=1')),
    ('URL fragment', profile.copyWith(serverUrl: 'https://example.com/#frag')),
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
      expect(logger.errors, [t.delete.secret.loginRequired]);
    });
  }

  test('does not expose malformed credentials', () async {
    await File(store.filePath).writeAsString(token);

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.delete.secret.loginRequired]);
  });

  Future<void> expireFirebaseToken() => store.saveProfile(
    'selected',
    profile.copyWith(
      authType: 'firebase',
      firebaseApiKey: 'test-api-key',
      refreshToken: 'private-refresh-token',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    ),
  );

  test('refreshes Firebase authentication before deleting', () async {
    await expireFirebaseToken();
    handler = (request) async {
      if (request.url.host == 'securetoken.googleapis.com') {
        return functionResponse(
          jsonEncode({
            'id_token': 'refreshed-id-token',
            'refresh_token': 'rotated-refresh-token',
            'expires_in': '3600',
          }),
          200,
        );
      }
      expect(request.method, 'POST');
      expect(request.headers['authorization'], 'Bearer refreshed-id-token');
      return success();
    };

    expect(await run(), 0);
    expect(requests, hasLength(2));
    final updated = (await store.getActiveProfile())!;
    expect(updated.token, 'refreshed-id-token');
    expect(updated.refreshToken, 'rotated-refresh-token');
    expect(updated.teamId, profile.teamId);
    expect((await store.get()).profiles['unused']!.token, 'unused-token');
  });

  test('does not delete when refreshing authentication fails', () async {
    await expireFirebaseToken();
    final credentials = await File(store.filePath).readAsBytes();
    handler = (_) async => functionResponse(privateValue, 400);

    expect(await run(), 1);
    expect(requests.single.url.host, 'securetoken.googleapis.com');
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.delete.secret.loginRequired]);
    expect(await File(store.filePath).readAsBytes(), credentials);
  });

  for (final status in [400, 401, 403, 404, 500, 302]) {
    test('reports HTTP $status without exposing the response body', () async {
      handler = (_) async => functionResponse(privateValue, status);

      expect(await run(), 1);
      expect(requests, hasLength(1));
      expect(logger.output, isEmpty);
      expect(logger.errors, [
        switch (status) {
          401 || 403 => t.delete.secret.loginRequired,
          404 => t.delete.secret.notFound(
            name: 'API_TOKEN',
            teamId: profile.teamId,
          ),
          _ => t.delete.secret.requestFailed(status: status),
        },
      ]);
    });
  }

  for (final error in [
    http.ClientException(privateValue),
    TimeoutException(privateValue),
  ]) {
    test('handles ${error.runtimeType} without exposing details', () async {
      handler = (_) async => throw error;

      expect(await run(), 1);
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.delete.secret.deleteFailed]);
    });
  }

  test('prints the deletion result in Japanese', () async {
    LocaleSettings.setLocaleSync(AppLocale.ja);

    expect(await run(), 0);
    expect(logger.output, ['チームselected/teamからシークレットAPI_TOKENを削除しました。']);
    expect(logger.errors, isEmpty);
  });
}
