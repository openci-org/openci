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

class _Logger implements Logger {
  final output = <String>[];
  final errors = <String>[];

  @override
  void stdout(String message) => output.add(message);

  @override
  void stderr(String message) => errors.add(message);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client extends MockClient {
  _Client(super.handler);

  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  const token = 'private-team-list-token';
  const refreshToken = 'private-refresh-token';
  const responseDetail = 'private-response-detail';
  final profile = AuthProfile(
    serverUrl: 'https://ci.example.com/proxy/',
    authType: 'firebase',
    token: token,
    refreshToken: refreshToken,
    firebaseApiKey: 'test-api-key',
    teamId: 'team-b',
    expiresAt: DateTime.utc(2100),
  );
  late Directory root;
  late CredentialStore store;
  late _Logger logger;
  late List<http.Request> requests;
  late List<_Client> clients;
  late MockClientHandler handler;
  late AppLocale originalLocale;

  Map<String, Object> team(String id, String name) => {
    'id': id,
    'name': name,
    'members': [responseDetail],
    'createdAt': '2026-10-01T00:00:00.000Z',
    'updatedAt': '2026-10-01T00:00:00.000Z',
  };

  http.Response response(Object? body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );

  setUp(() async {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    root = await Directory.systemTemp.createTemp('genuineci-list-teams-');
    store = CredentialStore(
      customFilePath: p.join(root.path, 'credentials.json'),
    );
    await store.set(
      CredentialConfig(
        activeProfile: 'remote',
        profiles: {
          'remote': profile,
          'local': profile.copyWith(
            serverUrl: 'http://localhost:8080',
            teamId: 'local-team',
          ),
        },
      ),
    );
    logger = _Logger();
    requests = [];
    clients = [];
    handler = (_) async => response([
      team('team-z', 'Beta'),
      team('team-b', 'Alpha'),
      team('team-a', 'Alpha'),
      team('team-ja', '日本語'),
    ]);
  });

  tearDown(() async {
    final output = [...logger.output, ...logger.errors].join('\n');
    for (final private in [
      token,
      refreshToken,
      responseDetail,
      'new-id-token',
      'rotated-refresh-token',
    ]) {
      expect(output, isNot(contains(private)));
    }
    expect(clients.every((client) => client.closed), isTrue);
    LocaleSettings.setLocaleSync(originalLocale);
    await root.delete(recursive: true);
  });

  Future<int?> run([List<String> arguments = const []]) {
    final runner = CommandRunner<int>('genuineci', 'test')
      ..addCommand(ListCommand(logger: logger, credentialStore: store));
    return http.runWithClient(
      () => runner.run(['list', 'teams', ...arguments]),
      () {
        final client = _Client((request) async {
          requests.add(request);
          return handler(request);
        });
        clients.add(client);
        return client;
      },
    );
  }

  test('lists sorted teams and marks the current one without saving', () async {
    final credentials = await File(store.filePath).readAsBytes();

    expect(await run(), 0);

    expect(logger.output, [
      '  Alpha (team-a)',
      '* Alpha (team-b)',
      '  Beta (team-z)',
      '  日本語 (team-ja)',
    ]);
    expect(logger.errors, isEmpty);
    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.url.toString(), 'https://ci.example.com/proxy/teams');
    expect(request.headers['authorization'], 'Bearer $token');
    expect(request.body, isEmpty);
    expect(await File(store.filePath).readAsBytes(), credentials);
    expect(root.listSync().map((entry) => p.basename(entry.path)), [
      'credentials.json',
    ]);
  });

  for (final id in ['', 'team-no-longer-available']) {
    test('lists teams even when the saved selection is "$id"', () async {
      await store.saveProfile('remote', profile.copyWith(teamId: id));

      expect(await run(), 0);
      expect(logger.output, hasLength(4));
      expect(logger.output.every((line) => line.startsWith('  ')), isTrue);
      expect((await store.getActiveProfile())!.teamId, id);
      expect(logger.errors, isEmpty);
    });
  }

  test('escapes terminal control characters in names and IDs', () async {
    const id = 'team\n\x1b[2J';
    await store.saveProfile('remote', profile.copyWith(teamId: id));
    handler = (_) async => response([team(id, '日本語\t\r\x9b')]);

    expect(await run(), 0);
    expect(logger.output, [r'* 日本語\x09\x0d\x9b (team\x0a\x1b[2J)']);
  });

  for (final locale in AppLocale.values) {
    test('reports an empty list successfully in $locale', () async {
      LocaleSettings.setLocaleSync(locale);
      handler = (_) async => response([]);

      expect(await run(), 0);
      expect(logger.output, [t.list.teams.empty]);
      expect(logger.errors, isEmpty);
    });

    test('requires login without saved credentials in $locale', () async {
      LocaleSettings.setLocaleSync(locale);
      await File(store.filePath).delete();

      expect(await run(), 1);
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.list.teams.loginRequired]);
      expect(clients, isEmpty);
    });

    test(
      'shows localized help without reading credentials in $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);
        await File(store.filePath).writeAsString(token);
        final help = <String>[];

        expect(
          await runZoned(
            () => run(['--help']),
            zoneSpecification: ZoneSpecification(
              print: (_, _, _, message) => help.add(message),
            ),
          ),
          isNull,
        );
        expect(help.join('\n'), contains('Usage: genuineci list teams'));
        expect(help.join('\n'), contains(t.list.teams.description));
        expect(clients, isEmpty);
        expect(logger.errors, isEmpty);
      },
    );
  }

  for (final local in [false, true]) {
    test('refreshes expired Firebase credentials: local=$local', () async {
      final config = await store.get();
      final selected = local ? 'local' : 'remote';
      final unused = local ? 'remote' : 'local';
      final activeProfile = config.profiles[selected]!.copyWith(
        expiresAt: DateTime.utc(2020),
        firebaseAuthEmulatorHost: local ? '127.0.0.1:9099' : null,
      );
      await store.saveProfile(selected, activeProfile);
      handler = (request) async {
        if (request.url.path.contains('/token')) {
          expect(
            request.url.host,
            local ? '127.0.0.1' : 'securetoken.googleapis.com',
          );
          expect(request.body, contains(refreshToken));
          return response({
            'id_token': 'new-id-token',
            'refresh_token': 'rotated-refresh-token',
            'expires_in': '3600',
          });
        }
        expect(
          request.url.toString(),
          '${activeProfile.serverUrl.replaceAll(RegExp(r'/$'), '')}/teams',
        );
        expect(request.headers['authorization'], 'Bearer new-id-token');
        return response([team(activeProfile.teamId, 'My team')]);
      };

      expect(await run(), 0);
      expect(requests, hasLength(2));
      expect(logger.output, ['* My team (${activeProfile.teamId})']);
      final after = await store.get();
      expect(after.activeProfile, selected);
      expect(after.profiles[unused], config.profiles[unused]);
      expect(after.profiles[selected]!.teamId, activeProfile.teamId);
      expect(after.profiles[selected]!.token, 'new-id-token');
      expect(after.profiles[selected]!.refreshToken, 'rotated-refresh-token');
    });
  }

  test('does not request teams when token refresh fails', () async {
    await store.saveProfile(
      'remote',
      profile.copyWith(expiresAt: DateTime.utc(2020)),
    );
    final credentials = await File(store.filePath).readAsBytes();
    handler = (_) async => http.Response(responseDetail, 400);

    expect(await run(), 1);
    expect(requests.single.url.host, 'securetoken.googleapis.com');
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.list.teams.loginRequired]);
    expect(await File(store.filePath).readAsBytes(), credentials);
  });

  for (final (label, invalidProfile) in <(String, AuthProfile?)>[
    ('missing active profile', null),
    ('legacy API key', profile.copyWith(authType: 'api_key')),
    ('blank token', profile.copyWith(token: ' ')),
    ('relative URL', profile.copyWith(serverUrl: '/server')),
    (
      'unsupported protocol',
      profile.copyWith(serverUrl: 'ftp://ci.example.com'),
    ),
    (
      'URL credentials',
      profile.copyWith(serverUrl: 'https://user:password@ci.example.com'),
    ),
    (
      'URL query',
      profile.copyWith(serverUrl: 'https://ci.example.com?token=$token'),
    ),
    (
      'URL fragment',
      profile.copyWith(serverUrl: 'https://ci.example.com#fragment'),
    ),
  ]) {
    test('requires login for $label before sending requests', () async {
      await store.set(
        CredentialConfig(
          activeProfile: 'remote',
          profiles: {'remote': ?invalidProfile},
        ),
      );

      expect(await run(), 1);
      expect(clients, isEmpty);
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.list.teams.loginRequired]);
    });
  }

  test('does not expose malformed credentials', () async {
    await File(store.filePath).writeAsString(token);

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.list.teams.loginRequired]);
  });

  for (final args in [
    ['unexpected'],
    ['--', 'unexpected'],
    ['--unknown'],
  ]) {
    test(
      'rejects invalid arguments before reading credentials: $args',
      () async {
        await expectLater(run(args), throwsA(isA<UsageException>()));
        expect(clients, isEmpty);
      },
    );
  }

  for (final status in [401, 403, 500]) {
    test('reports HTTP $status without exposing the response body', () async {
      handler = (_) async => http.Response(responseDetail, status);

      expect(await run(), 1);
      expect(logger.output, isEmpty);
      expect(logger.errors, [
        status == 401 || status == 403
            ? t.list.teams.loginRequired
            : t.list.teams.requestFailed(status: status),
      ]);
    });
  }

  test('does not print a partial list when a later team is invalid', () async {
    handler = (_) async =>
        response([team('team-a', 'Alpha'), team(' ', responseDetail)]);

    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.list.teams.invalidResponse]);
  });

  test('handles malformed JSON without printing the response', () async {
    handler = (_) async => http.Response(
      '{$responseDetail',
      200,
      headers: {'content-type': 'application/json'},
    );

    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.list.teams.invalidResponse]);
  });

  test('handles network failures without exposing exception details', () async {
    handler = (_) async => throw http.ClientException(responseDetail);

    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.list.teams.fetchFailed]);
  });
}
