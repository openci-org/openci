import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_cli/openci_cli.dart';
import 'package:openci_cli/src/commands/switch/select_team.dart';
import 'package:openci_shared/openci_shared.dart';
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
  const token = 'private-team-token';
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
  late TeamSelector selector;
  late List<({List<Team> teams, String currentTeamId})> selections;

  http.Response teamsResponse({bool empty = false}) => http.Response(
    jsonEncode([
      if (!empty)
        {
          'id': 'team-1',
          'name': 'Available team',
          'members': ['user-1'],
          'createdAt': '2026-10-01T00:00:00.000Z',
          'updatedAt': '2026-10-01T00:00:00.000Z',
        },
    ]),
    200,
    headers: {'content-type': 'application/json'},
  );

  setUp(() async {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    root = await Directory.systemTemp.createTemp('openci-switch-team-');
    store = CredentialStore(
      customFilePath: p.join(root.path, 'credentials.json'),
    );
    profile = AuthProfile(
      serverUrl: 'https://ci.example.com/proxy/',
      token: token,
      teamId: 'team-1',
      authType: 'firebase',
      refreshToken: refreshToken,
      firebaseApiKey: 'test-api-key',
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
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
    selections = [];
    selector = ({required teams, required currentTeamId}) async => teams.first;
  });

  tearDown(() async {
    final pickerMessage =
        logger.output.isNotEmpty ||
        logger.errors.any(
          [
            t.switchCommand.team.cancelled,
            t.switchCommand.team.inputFailed,
          ].contains,
        );
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
    if (logger.errors.isNotEmpty) expect(logger.output, isEmpty);
    expect(clients.every((client) => client.closed), isTrue);
    if (!pickerMessage) expect(selections, isEmpty);
    await root.delete(recursive: true);
  });

  Future<List<int>?> credentialsBytes() async {
    final file = File(store.filePath);
    return await file.exists() ? file.readAsBytes() : null;
  }

  Future<int?> run({
    List<String> arguments = const ['switch', 'team'],
    bool refreshExpected = false,
    bool teamChangeExpected = false,
  }) async {
    final before = await credentialsBytes();
    final runner = CommandRunner<int>('openci', 'test')
      ..addCommand(
        SwitchCommand(
          logger: logger,
          credentialStore: store,
          teamSelector: ({required teams, required currentTeamId}) async {
            expect(clients.every((client) => client.closed), isTrue);
            selections.add((teams: teams, currentTeamId: currentTeamId));
            return selector(teams: teams, currentTeamId: currentTeamId);
          },
        ),
      );
    try {
      return await http.runWithClient(() => runner.run(arguments), () {
        final client = _TrackingClient((request) async {
          requests.add(request);
          return handler(request);
        });
        clients.add(client);
        return client;
      });
    } finally {
      if (!refreshExpected && !teamChangeExpected) {
        expect(await credentialsBytes(), before);
      }
    }
  }

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    test(
      'fetches and selects the current team without writing: $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);

        expect(await run(), 0);

        final request = requests.single;
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://ci.example.com/proxy/teams');
        expect(request.headers['authorization'], 'Bearer $token');
        expect(logger.errors, isEmpty);
        expect(logger.output, [
          t.switchCommand.team.alreadyCurrent(team: 'Available team (team-1)'),
        ]);
        expect(selections.single.currentTeamId, 'team-1');
        expect(selections.single.teams.single.id, 'team-1');
      },
    );

    test(
      'handles an empty team list without changing credentials: $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);
        handler = (_) async => teamsResponse(empty: true);

        expect(await run(), 1);
        expect(logger.errors, [t.switchCommand.team.empty]);
      },
    );
  }

  for (final (name, serverUrl, emulatorHost) in [
    ('local', 'http://localhost:8080', '127.0.0.1:9099'),
    ('remote', 'https://ci.example.com/proxy/', null),
  ]) {
    test('uses the active $name profile server and token', () async {
      await store.saveProfile(
        name,
        profile.copyWith(
          serverUrl: serverUrl,
          firebaseAuthEmulatorHost: emulatorHost,
        ),
      );

      expect(await run(), 0);
      expect(
        requests.single.url.toString(),
        '${serverUrl.replaceAll(RegExp(r'/$'), '')}/teams',
      );
      expect(requests.single.headers['authorization'], 'Bearer $token');
      expect(logger.errors, isEmpty);
      expect(logger.output, [
        t.switchCommand.team.alreadyCurrent(team: 'Available team (team-1)'),
      ]);
      expect((await store.get()).activeProfile, name);
    });
  }

  for (final teamId in ['', 'removed-team']) {
    test('loads candidates when the saved team ID is "$teamId"', () async {
      await store.saveProfile('selected', profile.copyWith(teamId: teamId));

      expect(await run(teamChangeExpected: true), 0);
      expect(requests, hasLength(1));
      expect(logger.errors, isEmpty);
      expect(logger.output, [
        t.switchCommand.team.success(team: 'Available team (team-1)'),
      ]);
      expect(selections.single.currentTeamId, teamId);
      expect(await store.getActiveProfile(), profile);
    });
  }

  test(
    'passes sorted candidates and the active profile team to the picker',
    () async {
      handler = (_) async => http.Response(
        jsonEncode([
          for (final (id, name) in [
            ('team-z', 'Zulu'),
            ('team-2', 'Alpha'),
            ('team-1', 'Alpha'),
          ])
            {
              'id': id,
              'name': name,
              'members': ['user-1'],
              'createdAt': '2026-10-01T00:00:00.000Z',
              'updatedAt': '2026-10-01T00:00:00.000Z',
            },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
      await store.saveProfile('selected', profile.copyWith(teamId: 'team-z'));
      selector = ({required teams, required currentTeamId}) async => teams[1];

      expect(await run(teamChangeExpected: true), 0);
      expect(selections.single.teams.map((team) => team.id), [
        'team-1',
        'team-2',
        'team-z',
      ]);
      expect(selections.single.currentTeamId, 'team-z');
      expect(logger.errors, isEmpty);
      expect(logger.output, [
        t.switchCommand.team.success(team: 'Alpha (team-2)'),
      ]);
      expect(
        await store.getActiveProfile(),
        profile.copyWith(teamId: 'team-2'),
      );
      expect(requests.single.method, 'GET');
    },
  );

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    test(
      'cancels a single-candidate selection without saving: $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);
        selector = ({required teams, required currentTeamId}) async => null;

        expect(await run(), 1);
        expect(selections.single.teams, hasLength(1));
        expect(logger.errors, [t.switchCommand.team.cancelled]);
        expect(requests.single.method, 'GET');
      },
    );

    test(
      'reports picker failures without exposing their details: $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);
        selector = ({required teams, required currentTeamId}) async =>
            throw StateError(privateResponse);

        expect(await run(), 1);
        expect(selections, hasLength(1));
        expect(logger.errors, [t.switchCommand.team.inputFailed]);
      },
    );
  }

  test(
    'reports cancellation when the picker detects a non-interactive terminal',
    () async {
      selector = ({required teams, required currentTeamId}) => selectTeam(
        teams: teams,
        currentTeamId: currentTeamId,
        hasTerminal: false,
      );

      expect(await run(), 1);
      expect(logger.errors, [t.switchCommand.team.cancelled]);
      expect(requests.single.method, 'GET');
    },
  );

  for (final emulatorHost in <String?>[null, '127.0.0.1:9099']) {
    for (final expiry in [
      const Duration(minutes: -1),
      const Duration(seconds: 30),
    ]) {
      test(
        'refreshes before GET /teams: emulator=$emulatorHost expiry=$expiry',
        () async {
          await store.saveProfile(
            'selected',
            profile.copyWith(
              expiresAt: DateTime.now().toUtc().add(expiry),
              firebaseAuthEmulatorHost: emulatorHost,
            ),
          );
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
              return http.Response(
                jsonEncode({
                  'id_token': 'rotated-token',
                  'refresh_token': 'rotated-refresh-token',
                  'expires_in': '3600',
                }),
                200,
              );
            }
            expect(request.headers['authorization'], 'Bearer rotated-token');
            return teamsResponse();
          };

          expect(await run(refreshExpected: true), 0);
          expect(requests.map((request) => request.method), ['POST', 'GET']);
          expect(logger.errors, isEmpty);
          expect(logger.output, [
            t.switchCommand.team.alreadyCurrent(
              team: 'Available team (team-1)',
            ),
          ]);
          final saved = await store.get();
          final updated = saved.profiles['selected']!;
          expect(saved.activeProfile, 'selected');
          expect(saved.profiles['unused'], unused);
          expect(updated.token, 'rotated-token');
          expect(updated.refreshToken, 'rotated-refresh-token');
          expect(updated.expiresAt!.isAfter(DateTime.now().toUtc()), isTrue);
          expect(
            updated.copyWith(
              token: token,
              refreshToken: refreshToken,
              expiresAt: profile.expiresAt,
            ),
            profile.copyWith(firebaseAuthEmulatorHost: emulatorHost),
          );
        },
      );
    }
  }

  test(
    'keeps refreshed credentials and the selected team after an HTTP failure',
    () async {
      await store.saveProfile(
        'selected',
        profile.copyWith(expiresAt: DateTime.now().toUtc()),
      );
      handler = (request) async => request.method == 'POST'
          ? http.Response(
              jsonEncode({
                'id_token': 'rotated-token',
                'refresh_token': 'rotated-refresh-token',
                'expires_in': '3600',
              }),
              200,
            )
          : http.Response(privateResponse, 500);

      expect(await run(refreshExpected: true), 1);
      expect(logger.errors, [t.switchCommand.team.requestFailed(status: 500)]);
      final saved = await store.get();
      expect(saved.activeProfile, 'selected');
      expect(saved.profiles['unused'], unused);
      expect(saved.profiles['selected']!.token, 'rotated-token');
      expect(saved.profiles['selected']!.refreshToken, 'rotated-refresh-token');
      expect(saved.profiles['selected']!.teamId, profile.teamId);
    },
  );

  test('requires login when no credentials file exists', () async {
    await File(store.filePath).delete();

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.errors, [t.switchCommand.team.loginRequired]);
  });

  test('does not use another profile when the active one is missing', () async {
    await store.set(
      const CredentialConfig(
        activeProfile: 'absent',
        profiles: {'unused': unused},
      ),
    );

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.errors, [t.switchCommand.team.loginRequired]);
  });

  for (final (label, authType) in [
    ('legacy API key', 'api_key'),
    ('unsupported auth type', 'unknown'),
  ]) {
    test('requires Firebase login for $label', () async {
      await store.saveProfile('selected', profile.copyWith(authType: authType));

      expect(await run(), 1);
      expect(clients, isEmpty);
      expect(logger.errors, [t.switchCommand.team.loginRequired]);
    });
  }

  for (final serverUrl in [
    '',
    '/server',
    'ftp://ci.example.com',
    'https://user:password@ci.example.com',
    'https://ci.example.com/?token=$token',
    'https://ci.example.com/#fragment',
  ]) {
    test('requires login for an invalid server URL: $serverUrl', () async {
      await store.saveProfile(
        'selected',
        profile.copyWith(serverUrl: serverUrl),
      );

      expect(await run(), 1);
      expect(clients, isEmpty);
      expect(logger.errors, [t.switchCommand.team.loginRequired]);
    });
  }

  for (final emptyToken in ['', ' ']) {
    test(
      'requires login for a blank token: ${jsonEncode(emptyToken)}',
      () async {
        await store.saveProfile(
          'selected',
          profile.copyWith(
            token: emptyToken,
            refreshToken: '',
            firebaseApiKey: '',
          ),
        );

        expect(await run(), 1);
        expect(clients, isEmpty);
        expect(logger.errors, [t.switchCommand.team.loginRequired]);
      },
    );
  }

  test('does not expose malformed credentials', () async {
    await File(store.filePath).writeAsString(token);

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.errors, [t.switchCommand.team.loginRequired]);
  });

  for (final emulatorHost in <String?>[null, '127.0.0.1:9099']) {
    test(
      'stops after a failed refresh without fallback: emulator=$emulatorHost',
      () async {
        await store.saveProfile(
          'selected',
          profile.copyWith(
            expiresAt: DateTime.now().toUtc(),
            firebaseAuthEmulatorHost: emulatorHost,
          ),
        );
        handler = (_) async => http.Response(privateResponse, 400);

        expect(await run(), 1);
        expect(requests.single.method, 'POST');
        expect(
          requests.single.url.host,
          emulatorHost == null ? 'securetoken.googleapis.com' : '127.0.0.1',
        );
        expect(logger.errors, [t.switchCommand.team.loginRequired]);
      },
    );
  }

  for (final status in [401, 403, 500, 503]) {
    test('handles HTTP $status without exposing the response body', () async {
      handler = (_) async => http.Response(privateResponse, status);

      expect(await run(), 1);
      expect(logger.errors, [
        status == 401 || status == 403
            ? t.switchCommand.team.loginRequired
            : t.switchCommand.team.requestFailed(status: status),
      ]);
    });
  }

  for (final body in [
    'null',
    '{"teams":[]}',
    '[{"id":""}]',
    '[{"id":42}]',
    '{private-response-body',
  ]) {
    test(
      'handles malformed responses without printing candidates: $body',
      () async {
        handler = (_) async => http.Response(
          body,
          200,
          headers: {'content-type': 'application/json'},
        );

        expect(await run(), 1);
        expect(logger.errors, [t.switchCommand.team.fetchFailed]);
      },
    );
  }

  for (final error in [
    http.ClientException(privateResponse),
    TimeoutException(privateResponse),
  ]) {
    test('handles ${error.runtimeType} without changing credentials', () async {
      handler = (_) async => throw error;

      expect(await run(), 1);
      expect(logger.errors, [t.switchCommand.team.fetchFailed]);
    });
  }

  test('rejects positional arguments before reading credentials', () async {
    await File(store.filePath).writeAsString(token);

    await expectLater(
      run(arguments: ['switch', 'team', 'unexpected']),
      throwsA(isA<UsageException>()),
    );
    expect(clients, isEmpty);
    expect(logger.errors, isEmpty);
  });

  test('help does not read credentials or issue requests', () async {
    await File(store.filePath).writeAsString(token);

    expect(await run(arguments: ['switch', 'team', '--help']), isNull);
    expect(clients, isEmpty);
    expect(logger.errors, isEmpty);
  });
}
