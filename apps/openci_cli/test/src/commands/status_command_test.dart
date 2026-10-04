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

class _ChangingCredentialStore extends CredentialStore {
  _ChangingCredentialStore({required String path, required this.nextConfig})
    : super(customFilePath: path);

  final CredentialConfig nextConfig;
  int reads = 0;

  @override
  Future<CredentialConfig> get() async =>
      ++reads == 1 ? super.get() : nextConfig;
}

void main() {
  const token = 'private-status-token';
  const refreshToken = 'private-refresh-token';
  const privateResponse = 'private-response-body';
  const unused = AuthProfile(token: 'unused-token', teamId: 'unused-team');
  late Directory root;
  late CredentialStore store;
  late AuthProfile profile;
  late AppLocale originalLocale;
  late _RecordingLogger logger;
  late List<http.Request> requests;
  late List<_TrackingClient> clients;
  late MockClientHandler handler;

  Map<String, Object> team(String id, String name) => {
    'id': id,
    'name': name,
    'members': ['user-1'],
    'createdAt': '2026-10-01T00:00:00.000Z',
    'updatedAt': '2026-10-01T00:00:00.000Z',
  };

  http.Response response(Object? body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response teamsResponse() => response([
    team('other-team', 'Current team'),
    team('team-current', 'Current team'),
  ]);

  setUp(() async {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    root = await Directory.systemTemp.createTemp('genuineci-status-');
    store = CredentialStore(
      customFilePath: p.join(root.path, 'credentials.json'),
    );
    profile = AuthProfile(
      serverUrl: 'https://ci.example.com/proxy/',
      token: token,
      teamId: 'team-current',
      authType: 'firebase',
      refreshToken: refreshToken,
      firebaseApiKey: 'test-api-key',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    await store.set(
      CredentialConfig(
        activeProfile: 'selected',
        profiles: {'selected': profile, 'unused': unused},
      ),
    );
    logger = _RecordingLogger();
    requests = [];
    clients = [];
    handler = (_) async => teamsResponse();
  });

  tearDown(() async {
    LocaleSettings.setLocaleSync(originalLocale);
    final messages = [...logger.output, ...logger.errors].join('\n');
    for (final secret in [
      token,
      refreshToken,
      privateResponse,
      'rotated-token',
      'rotated-refresh-token',
      'unused-token',
    ]) {
      expect(messages, isNot(contains(secret)));
    }
    if (logger.errors.isNotEmpty) {
      expect(
        logger.output.where(
          (line) => line.startsWith('Team name:') || line.startsWith('チーム名:'),
        ),
        isEmpty,
      );
    }
    expect(clients.every((client) => client.closed), isTrue);
    await root.delete(recursive: true);
  });

  Future<List<int>?> credentialsBytes() async {
    final file = File(store.filePath);
    return await file.exists() ? file.readAsBytes() : null;
  }

  Future<int?> run({
    List<String> arguments = const [],
    bool refreshExpected = false,
  }) async {
    final before = await credentialsBytes();
    final runner = CommandRunner<int>('genuineci', 'test')
      ..addCommand(StatusCommand(logger: logger, credentialStore: store));
    try {
      return await http.runWithClient(
        () => runner.run(['status', ...arguments]),
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
      if (!refreshExpected) expect(await credentialsBytes(), before);
    }
  }

  for (final (locale, output) in [
    (
      AppLocale.en,
      [
        'Profile: selected',
        'Server: https://ci.example.com/proxy/',
        'Selected team ID: team-current',
        'Team name: Current team',
      ],
    ),
    (
      AppLocale.ja,
      [
        'プロファイル: selected',
        'サーバー: https://ci.example.com/proxy/',
        '選択中のチームID: team-current',
        'チーム名: Current team',
      ],
    ),
  ]) {
    test('prints only the selected team, matched by ID: $locale', () async {
      LocaleSettings.setLocaleSync(locale);

      expect(await run(), 0);

      final request = requests.single;
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://ci.example.com/proxy/teams');
      expect(request.headers['authorization'], 'Bearer $token');
      expect(request.body, isEmpty);
      expect(logger.output, output);
      expect(logger.errors, isEmpty);
    });
  }

  test('shows the latest name after the team is renamed', () async {
    handler = (_) async => response([team('team-current', '新しいチーム名')]);

    expect(await run(), 0);
    expect(logger.output.last, 'Team name: 新しいチーム名');
    expect(logger.errors, isEmpty);
  });

  test('escapes terminal controls in both the name and ID', () async {
    const id = 'team\r\x1b[2J';
    await store.saveProfile('selected', profile.copyWith(teamId: id));
    handler = (_) async => response([team(id, '日本語\n\x9b31m')]);

    expect(await run(), 0);
    expect(logger.output.skip(2), [
      r'Selected team ID: team\x0d\x1b[2J',
      r'Team name: 日本語\x0a\x9b31m',
    ]);
  });

  for (final (name, serverUrl, emulatorHost) in [
    ('local', 'http://localhost:8080', '127.0.0.1:9099'),
    ('remote', 'https://ci.example.com/proxy/', null),
  ]) {
    test('refreshes and uses the active $name profile', () async {
      final active = profile.copyWith(
        serverUrl: serverUrl,
        firebaseAuthEmulatorHost: emulatorHost,
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      await store.saveProfile(name, active);
      handler = (request) async {
        if (request.method == 'POST') {
          expect(
            request.url.toString(),
            emulatorHost == null
                ? 'https://securetoken.googleapis.com/v1/token?key=test-api-key'
                : 'http://127.0.0.1:9099/securetoken.googleapis.com/v1/token?key=test-api-key',
          );
          expect(request.bodyFields, {
            'grant_type': 'refresh_token',
            'refresh_token': refreshToken,
          });
          return response({
            'id_token': 'rotated-token',
            'refresh_token': 'rotated-refresh-token',
            'expires_in': '3600',
          });
        }
        expect(
          request.url.toString(),
          '${serverUrl.replaceAll(RegExp(r'/$'), '')}/teams',
        );
        expect(request.headers['authorization'], 'Bearer rotated-token');
        return teamsResponse();
      };

      expect(await run(refreshExpected: true), 0);
      expect(requests.map((request) => request.method), ['POST', 'GET']);
      expect(logger.output, [
        'Profile: $name',
        'Server: $serverUrl',
        'Selected team ID: team-current',
        'Team name: Current team',
      ]);
      expect(logger.errors, isEmpty);
      final saved = await store.get();
      final updated = saved.profiles[name]!;
      expect(saved.activeProfile, name);
      expect(saved.profiles['selected'], profile);
      expect(saved.profiles['unused'], unused);
      expect(updated.token, 'rotated-token');
      expect(updated.refreshToken, 'rotated-refresh-token');
      expect(updated.expiresAt!.isAfter(DateTime.now().toUtc()), isTrue);
      expect(
        updated.copyWith(
          token: token,
          refreshToken: refreshToken,
          expiresAt: active.expiresAt,
        ),
        active,
      );
    });
  }

  test('shows a login hint without a credentials file', () async {
    await File(store.filePath).delete();

    expect(await run(), 0);
    expect(clients, isEmpty);
    expect(logger.output, [t.status.noActiveProfile]);
    expect(logger.errors, isEmpty);
  });

  test(
    'does not fall back to another profile if the active one is missing',
    () async {
      await store.set(
        CredentialConfig(
          activeProfile: 'missing',
          profiles: {'unused': profile},
        ),
      );

      expect(await run(), 1);
      expect(clients, isEmpty);
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.status.profileMissing(profile: 'missing')]);
    },
  );

  for (final (label, invalidProfile) in <(String, AuthProfile Function())>[
    ('API key authentication', () => profile.copyWith(authType: 'api_key')),
    ('blank token', () => profile.copyWith(token: ' ')),
    ('relative URL', () => profile.copyWith(serverUrl: '/server')),
    (
      'unsupported protocol',
      () => profile.copyWith(serverUrl: 'ftp://ci.example.com'),
    ),
    (
      'URL credentials',
      () => profile.copyWith(serverUrl: 'https://user:password@ci.example.com'),
    ),
    (
      'URL query',
      () => profile.copyWith(serverUrl: 'https://ci.example.com/?token=$token'),
    ),
    (
      'URL fragment',
      () => profile.copyWith(serverUrl: 'https://ci.example.com/#fragment'),
    ),
  ]) {
    test('requires login for $label without making a request', () async {
      await store.saveProfile('selected', invalidProfile());

      expect(await run(), 1);
      expect(clients, isEmpty);
      expect(logger.errors, [t.status.loginRequired]);
    });
  }

  test('hides malformed credentials', () async {
    await File(store.filePath).writeAsString('{"token":"$token"');

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.status.readFailed]);
  });

  for (final changeProfileName in [false, true]) {
    test(
      'does not mix saved context with a changed profile or team: $changeProfileName',
      () async {
        store = _ChangingCredentialStore(
          path: store.filePath,
          nextConfig: CredentialConfig(
            activeProfile: changeProfileName ? 'other' : 'selected',
            profiles: {
              'selected': profile.copyWith(teamId: 'different-team'),
              'other': profile,
            },
          ),
        );

        expect(await run(), 1);
        expect(clients, isEmpty);
        expect(logger.errors, [t.status.profileChanged]);
      },
    );
  }

  test('stops when refreshing authentication fails', () async {
    await store.saveProfile(
      'selected',
      profile.copyWith(expiresAt: DateTime.now().toUtc()),
    );
    handler = (_) async => http.Response(privateResponse, 400);

    expect(await run(), 1);
    expect(requests.single.method, 'POST');
    expect(logger.errors, [t.status.loginRequired]);
  });

  test('asks to select a team when no team is saved', () async {
    await store.saveProfile('selected', profile.copyWith(teamId: ' '));

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.errors, [t.status.noTeamSelected]);
  });

  test('reports no memberships without changing the saved team', () async {
    handler = (_) async => response([]);

    expect(await run(), 1);
    expect(logger.errors, [t.status.noTeams]);
  });

  test(
    'does not display another team when the selected team is unavailable',
    () async {
      handler = (_) async => response([team('other-team', 'Other team')]);

      expect(await run(), 1);
      expect(logger.errors, [t.status.teamNotFound]);
    },
  );

  for (final status in [401, 403, 500, 503]) {
    test('handles HTTP $status without exposing the response', () async {
      handler = (_) async => http.Response(privateResponse, status);

      expect(await run(), 1);
      expect(logger.errors, [
        status == 401 || status == 403
            ? t.status.loginRequired
            : t.status.requestFailed(status: status),
      ]);
    });
  }

  for (final (label, body) in <(String, Object?)>[
    ('null', null),
    ('object instead of list', {'teams': []}),
    (
      'invalid team',
      [
        {'name': privateResponse},
      ],
    ),
  ]) {
    test('handles an invalid team response: $label', () async {
      handler = (_) async => response(body);

      expect(await run(), 1);
      expect(logger.errors, [t.status.invalidResponse]);
    });
  }

  test('handles a non-JSON success response', () async {
    handler = (_) async => http.Response(privateResponse, 200);

    expect(await run(), 1);
    expect(logger.errors, [t.status.invalidResponse]);
  });

  for (final error in [
    const SocketException(privateResponse),
    TimeoutException(privateResponse),
  ]) {
    test('handles ${error.runtimeType} without exposing its details', () async {
      handler = (_) async => throw error;

      expect(await run(), 1);
      expect(logger.errors, [t.status.fetchFailed]);
      expect(logger.output, [
        'Profile: selected',
        'Server: https://ci.example.com/proxy/',
        'Selected team ID: team-current',
      ]);
    });
  }

  for (final argument in ['unexpected', '--unknown']) {
    test(
      'rejects $argument before reading credentials or making requests',
      () async {
        await expectLater(
          run(arguments: [argument]),
          throwsA(
            isA<UsageException>().having(
              (error) => error.usage,
              'usage',
              contains('Usage: genuineci status'),
            ),
          ),
        );
        expect(clients, isEmpty);
        expect(logger.output, isEmpty);
        expect(logger.errors, isEmpty);
      },
    );
  }
}
