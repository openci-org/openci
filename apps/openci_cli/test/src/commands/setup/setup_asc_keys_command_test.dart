import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:genuineci_cli/src/asc/asc_cli.dart';
import 'package:genuineci_cli/src/asc/asc_release.dart';
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
  const token = 'private-setup-token';
  const refreshToken = 'private-refresh-token';
  const privateValue = 'private-secret-value';
  const unused = AuthProfile(token: 'unused-token', teamId: 'unused-team');
  late Directory root;
  late CredentialStore store;
  late AuthProfile profile;
  late AppLocale originalLocale;
  late _RecordingLogger logger;
  late List<http.Request> requests;
  late List<_TrackingClient> clients;
  late MockClientHandler handler;
  late int preparationCount;
  late Future<File> Function() prepareAsc;

  List<String> preparationMessages() => [
    t.setup.ascKeys.preparingAsc(version: AscRelease.version),
    t.setup.ascKeys.ascReady(
      version: AscRelease.version,
      path: p.join(root.path, 'asc'),
    ),
  ];

  Map<String, Object> team(String id, String name) => {
    'id': id,
    'name': name,
    'members': ['user-1'],
    'createdAt': '2026-10-01T00:00:00.000Z',
    'updatedAt': '2026-10-01T00:00:00.000Z',
  };

  http.Response response(Object? body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response teamsResponse() => response([
    team('unused-team', 'Other team'),
    team(profile.teamId, 'OpenCI'),
  ]);

  http.Response secretsResponse(List<String> names) => response({
    'success': true,
    'secrets': [
      for (final name in names) {'name': name, 'encryptedValue': privateValue},
    ],
  });

  bool isTeamsRequest(http.Request request) =>
      request.url.path.endsWith('/teams');

  setUp(() async {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    root = await Directory.systemTemp.createTemp('genuineci-setup-asc-keys-');
    store = CredentialStore(
      customFilePath: p.join(root.path, 'credentials.json'),
    );
    profile = AuthProfile(
      serverUrl: 'https://ci.example.com/proxy/',
      token: token,
      teamId: 'selected/team',
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
    preparationCount = 0;
    prepareAsc = () async => File(p.join(root.path, 'asc'));
    handler = (request) async => isTeamsRequest(request)
        ? teamsResponse()
        : secretsResponse(['OPENCI_ASC_API_KEY', 'UNRELATED_SECRET']);
  });

  tearDown(() async {
    final messages = [...logger.output, ...logger.errors].join('\n');
    for (final secret in [token, refreshToken, privateValue, 'unused-token']) {
      expect(messages, isNot(contains(secret)));
    }
    expect(clients.every((client) => client.closed), isTrue);
    if (!logger.output.contains(t.setup.ascKeys.notRegistered)) {
      expect(preparationCount, 0);
    }
    LocaleSettings.setLocaleSync(originalLocale);
    await root.delete(recursive: true);
  });

  Future<int?> run([List<String> arguments = const ['asc-keys']]) {
    final runner = CommandRunner<int>('genuineci', 'test')
      ..addCommand(
        SetupCommand(
          logger: logger,
          credentialStore: store,
          prepareAsc: () {
            preparationCount++;
            expect(clients.every((client) => client.closed), isTrue);
            return prepareAsc();
          },
        ),
      );
    return http.runWithClient(() => runner.run(['setup', ...arguments]), () {
      final client = _TrackingClient((request) async {
        requests.add(request);
        return handler(request);
      });
      clients.add(client);
      return client;
    });
  }

  List<String> contextMessages() => [
    t.setup.ascKeys.server(value: profile.serverUrl),
    t.setup.ascKeys.team(name: 'OpenCI', id: profile.teamId),
  ];

  test('checks the active team and registered secret without writes', () async {
    final credentials = await File(store.filePath).readAsBytes();

    expect(await run(), 0);

    expect(requests.map((request) => request.url.toString()), [
      'https://ci.example.com/proxy/teams',
      'https://ci.example.com/proxy/teams/selected%2Fteam/secrets',
    ]);
    for (final request in requests) {
      expect(request.method, 'GET');
      expect(request.headers['authorization'], 'Bearer $token');
      expect(request.body, isEmpty);
    }
    expect(logger.output, [...contextMessages(), t.setup.ascKeys.registered]);
    expect(logger.errors, isEmpty);
    expect(await File(store.filePath).readAsBytes(), credentials);
    expect(root.listSync().map((entry) => p.basename(entry.path)), [
      'credentials.json',
    ]);
  });

  test(
    'reports incomplete setup when the exact ASC secret is absent',
    () async {
      handler = (request) async => isTeamsRequest(request)
          ? teamsResponse()
          : secretsResponse([
              'OPENCI_IOS_CERTIFICATE_PRIVATE_KEY',
              'OPENCI_ASC_API_KEY_OLD',
              'ASC_KEY',
            ]);

      expect(await run(), 1);

      expect(logger.output, [
        ...contextMessages(),
        t.setup.ascKeys.notRegistered,
        ...preparationMessages(),
      ]);
      expect(preparationCount, 1);
      expect(logger.errors, [t.setup.ascKeys.creationUnavailable]);
      expect(requests, hasLength(2));
      expect(requests.every((request) => request.method == 'GET'), isTrue);
    },
  );

  test('reports incomplete setup for a team without secrets', () async {
    handler = (request) async =>
        isTeamsRequest(request) ? teamsResponse() : secretsResponse([]);

    expect(await run(), 1);
    expect(logger.output, [
      ...contextMessages(),
      t.setup.ascKeys.notRegistered,
      ...preparationMessages(),
    ]);
    expect(preparationCount, 1);
    expect(logger.errors, [t.setup.ascKeys.creationUnavailable]);
  });

  test('refreshes authentication and preserves the selected profile', () async {
    await store.saveProfile(
      'selected',
      profile.copyWith(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      ),
    );
    handler = (request) async {
      if (request.url.host == 'securetoken.googleapis.com') {
        return response({
          'id_token': 'new-id-token',
          'refresh_token': 'rotated-refresh-token',
          'expires_in': '3600',
        });
      }
      expect(request.headers['authorization'], 'Bearer new-id-token');
      return isTeamsRequest(request)
          ? teamsResponse()
          : secretsResponse(['OPENCI_ASC_API_KEY']);
    };

    expect(await run(), 0);
    expect(requests, hasLength(3));
    final config = await store.get();
    expect(config.activeProfile, 'selected');
    expect(config.profiles['unused'], unused);
    expect(config.profiles['selected']!.token, 'new-id-token');
    expect(config.profiles['selected']!.teamId, profile.teamId);
    expect(
      [...logger.output, ...logger.errors].join(),
      isNot(contains('token')),
    );
  });

  test('stops when the Firebase token cannot be refreshed', () async {
    await store.saveProfile(
      'selected',
      profile.copyWith(expiresAt: DateTime.utc(2020)),
    );
    handler = (_) async => response(privateValue, status: 401);

    expect(await run(), 1);
    expect(requests.single.url.host, 'securetoken.googleapis.com');
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.setup.ascKeys.loginRequired]);
  });

  test('requires login with no active profile', () async {
    await store.set(const CredentialConfig());

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.setup.ascKeys.loginRequired]);
  });

  for (final invalid in [
    'legacy authentication',
    'blank token',
    'relative URL',
    'URL credentials',
    'URL query',
    'URL fragment',
    'unsupported protocol',
  ]) {
    test('rejects $invalid before contacting the server', () async {
      final invalidProfile = switch (invalid) {
        'legacy authentication' => profile.copyWith(authType: 'api_key'),
        'blank token' => profile.copyWith(token: ' '),
        'relative URL' => profile.copyWith(serverUrl: '/server'),
        'URL credentials' => profile.copyWith(
          serverUrl: 'https://user:$token@example.com',
        ),
        'URL query' => profile.copyWith(
          serverUrl: 'https://example.com/?token=$token',
        ),
        'URL fragment' => profile.copyWith(
          serverUrl: 'https://example.com/#$token',
        ),
        _ => profile.copyWith(serverUrl: 'ftp://example.com'),
      };
      await store.saveProfile('selected', invalidProfile);

      expect(await run(), 1);
      expect(clients, isEmpty);
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.setup.ascKeys.loginRequired]);
    });
  }

  test('does not expose malformed local credentials', () async {
    await File(store.filePath).writeAsString(token);

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.errors, [t.setup.ascKeys.loginRequired]);
  });

  test('asks for a team when none is selected', () async {
    await store.saveProfile('selected', profile.copyWith(teamId: ' '));

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.errors, [t.setup.ascKeys.noTeamSelected]);
  });

  for (final hasOtherTeam in [false, true]) {
    test('stops if the selected team is unavailable ($hasOtherTeam)', () async {
      handler = (_) async =>
          response([if (hasOtherTeam) team('other-team', 'OpenCI')]);

      expect(await run(), 1);
      expect(requests, hasLength(1));
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.setup.ascKeys.teamNotFound]);
    });
  }

  for (final endpoint in ['teams', 'secrets']) {
    for (final status in [401, 403, 500]) {
      test('handles $endpoint HTTP $status without response details', () async {
        handler = (request) async =>
            endpoint == 'secrets' && isTeamsRequest(request)
            ? teamsResponse()
            : response(privateValue, status: status);

        expect(await run(), 1);
        expect(logger.output, isEmpty);
        expect(logger.errors, [
          status == 401 || status == 403
              ? t.setup.ascKeys.loginRequired
              : t.setup.ascKeys.requestFailed(status: status),
        ]);
      });
    }

    test('rejects a malformed $endpoint response', () async {
      handler = (request) async =>
          endpoint == 'secrets' && isTeamsRequest(request)
          ? teamsResponse()
          : response({
              'success': true,
              'secrets': [
                {'name': 'OPENCI_ASC_API_KEY'},
                {'name': null, 'encryptedValue': privateValue},
              ],
            });

      expect(await run(), 1);
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.setup.ascKeys.invalidResponse]);
    });
  }

  test('does not expose network exception details', () async {
    handler = (_) async => throw http.ClientException(privateValue);

    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.setup.ascKeys.checkFailed]);
  });

  test('escapes terminal controls in the destination team name', () async {
    handler = (request) async => isTeamsRequest(request)
        ? response([team(profile.teamId, 'OpenCI\x1b[2J\nOther')])
        : secretsResponse(['OPENCI_ASC_API_KEY']);

    expect(await run(), 0);
    expect(
      logger.output[1],
      t.setup.ascKeys.team(name: r'OpenCI\x1b[2J\x0aOther', id: profile.teamId),
    );
  });

  test('uses Japanese messages for the selected locale', () async {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    handler = (request) async =>
        isTeamsRequest(request) ? teamsResponse() : secretsResponse([]);

    expect(await run(), 1);
    expect(logger.output, [
      ...contextMessages(),
      t.setup.ascKeys.notRegistered,
      ...preparationMessages(),
    ]);
    expect(logger.output[1], contains('保存先チーム'));
    expect(logger.errors, [t.setup.ascKeys.creationUnavailable]);
    expect(logger.errors.single, contains('セットアップは未完了'));
  });

  for (final failure in AscCliFailure.values) {
    test('reports asc $failure separately from GenuineCI API errors', () async {
      handler = (request) async =>
          isTeamsRequest(request) ? teamsResponse() : secretsResponse([]);
      prepareAsc = () async => throw AscCliException(failure);

      expect(await run(), 1);
      expect(preparationCount, 1);
      expect(logger.errors, [
        switch (failure) {
          AscCliFailure.unsupportedPlatform => t.setup.ascKeys.ascUnsupported,
          AscCliFailure.cache => t.setup.ascKeys.ascCacheFailed,
          AscCliFailure.download => t.setup.ascKeys.ascDownloadFailed,
          AscCliFailure.checksum => t.setup.ascKeys.ascChecksumFailed,
          AscCliFailure.permission => t.setup.ascKeys.ascPermissionFailed,
        },
      ]);
      expect(logger.output.last, preparationMessages().first);
    });
  }

  test('does not expose unexpected asc preparation errors', () async {
    handler = (request) async =>
        isTeamsRequest(request) ? teamsResponse() : secretsResponse([]);
    prepareAsc = () async => throw StateError(privateValue);

    expect(await run(), 1);
    expect(logger.errors, [t.setup.ascKeys.ascPreparationFailed]);
  });

  test('escapes terminal controls in the asc cache path', () async {
    handler = (request) async =>
        isTeamsRequest(request) ? teamsResponse() : secretsResponse([]);
    prepareAsc = () async => File('/cache/asc\x1b[2J\nother');

    expect(await run(), 1);
    expect(logger.output.last, contains(r'/cache/asc\x1b[2J\x0aother'));
  });

  test('rejects positional arguments before reading credentials', () async {
    await File(store.filePath).writeAsString(token);

    await expectLater(
      run(['asc-keys', 'unexpected']),
      throwsA(isA<UsageException>()),
    );
    expect(clients, isEmpty);
    expect(logger.errors, isEmpty);
  });

  for (final arguments in [
    ['--help'],
    ['asc-keys', '--help'],
  ]) {
    test('help $arguments does not authenticate or call the API', () async {
      await File(store.filePath).writeAsString(token);

      expect(await run(arguments), isNull);
      expect(clients, isEmpty);
      expect(logger.errors, isEmpty);
    });
  }
}
