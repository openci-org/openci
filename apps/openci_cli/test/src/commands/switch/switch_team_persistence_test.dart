import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:genuineci_cli/src/commands/switch/select_team.dart';
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

class _CountingCredentialStore extends CredentialStore {
  _CountingCredentialStore(String path) : super(customFilePath: path);

  int writes = 0;

  @override
  Future<void> set(CredentialConfig config) async {
    writes++;
    await super.set(config);
  }
}

void main() {
  const unused = AuthProfile(
    serverUrl: 'http://localhost:8080',
    token: 'unused-token',
    teamId: 'unused-team',
  );
  final permissionTestsSupported =
      !Platform.isWindows &&
      Process.runSync('id', ['-u']).stdout.toString().trim() != '0';
  late Directory root;
  late _CountingCredentialStore store;
  late CredentialStore otherStore;
  late AuthProfile profile;
  late CredentialConfig initial;
  late AppLocale originalLocale;
  late _RecordingLogger logger;
  late TeamSelector selector;
  late MockClientHandler handler;
  late List<http.Request> requests;

  http.Response teamsResponse({String nextName = 'Next team'}) => http.Response(
    jsonEncode([
      for (final (id, name) in [
        ('team-1', 'Current team'),
        ('team-2', nextName),
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

  setUp(() async {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    root = await Directory.systemTemp.createTemp('openci-switch-persistence-');
    store = _CountingCredentialStore(p.join(root.path, 'credentials.json'));
    otherStore = CredentialStore(customFilePath: store.filePath);
    profile = AuthProfile(
      serverUrl: 'https://ci.example.com/proxy/',
      token: 'private-token',
      teamId: 'team-1',
      authType: 'firebase',
      refreshToken: 'private-refresh-token',
      firebaseApiKey: 'private-api-key',
      firebaseAuthEmulatorHost: '127.0.0.1:9099',
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
    );
    initial = CredentialConfig(
      activeProfile: 'selected',
      profiles: {'selected': profile, 'unused': unused},
    );
    await store.set(initial);
    store.writes = 0;
    logger = _RecordingLogger();
    requests = [];
    handler = (_) async => teamsResponse();
    selector = ({required teams, required currentTeamId}) async => teams.last;
  });

  tearDown(() async {
    LocaleSettings.setLocaleSync(originalLocale);
    final messages = [...logger.output, ...logger.errors].join('\n');
    for (final secret in [
      'private-token',
      'private-refresh-token',
      'private-api-key',
      'rotated-token',
      'rotated-refresh-token',
      'unused-token',
      'private-value',
    ]) {
      expect(messages, isNot(contains(secret)));
    }
    await root.delete(recursive: true);
  });

  Future<int?> run() {
    final runner = CommandRunner<int>('genuineci', 'test')
      ..addCommand(
        SwitchCommand(
          logger: logger,
          credentialStore: store,
          teamSelector: selector,
        ),
      );
    return http.runWithClient(() => runner.run(['switch', 'team']), () {
      return MockClient((request) async {
        requests.add(request);
        return handler(request);
      });
    });
  }

  CredentialConfig withTeam(CredentialConfig config, String teamId) =>
      config.copyWith(
        profiles: {
          ...config.profiles,
          config.activeProfile: config.profiles[config.activeProfile]!.copyWith(
            teamId: teamId,
          ),
        },
      );

  Future<void> expireProfile({String? emulatorHost}) async {
    await otherStore.saveProfile(
      'selected',
      profile.copyWith(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
        firebaseAuthEmulatorHost: emulatorHost,
      ),
    );
    handler = (request) async {
      if (request.method == 'POST') {
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
  }

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    test('changes only the active profile team ID: $locale', () async {
      LocaleSettings.setLocaleSync(locale);

      expect(await run(), 0);

      expect(await otherStore.get(), withTeam(initial, 'team-2'));
      expect(store.writes, 1);
      expect(logger.output, [
        t.switchCommand.team.success(team: 'Next team (team-2)'),
      ]);
      expect(logger.errors, isEmpty);
      if (!Platform.isWindows) {
        expect((await File(store.filePath).stat()).mode & 0x1ff, 0x180);
      }
      expect(root.listSync().map((entry) => p.basename(entry.path)), [
        'credentials.json',
      ]);
    });

    test(
      'selecting the current team does not write credentials: $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);
        // Noncanonical formatting makes even an equivalent rewrite detectable.
        await File(store.filePath).writeAsString(
          const JsonEncoder.withIndent('  ').convert(initial.toJson()),
        );
        final before = await File(store.filePath).readAsBytes();
        selector = ({required teams, required currentTeamId}) async =>
            teams.first;

        expect(await run(), 0);

        expect(store.writes, 0);
        expect(await File(store.filePath).readAsBytes(), before);
        expect(logger.output, [
          t.switchCommand.team.alreadyCurrent(team: 'Current team (team-1)'),
        ]);
        expect(logger.errors, isEmpty);
      },
    );
  }

  for (final emulatorHost in <String?>[null, '127.0.0.1:9099']) {
    test('preserves refreshed credentials: emulator=$emulatorHost', () async {
      await expireProfile(emulatorHost: emulatorHost);
      late CredentialConfig authenticated;
      selector = ({required teams, required currentTeamId}) async {
        authenticated = await otherStore.get();
        expect(currentTeamId, 'team-1');
        return teams.last;
      };

      expect(await run(), 0);

      final refreshed = authenticated.profiles['selected']!;
      expect(refreshed.token, 'rotated-token');
      expect(refreshed.refreshToken, 'rotated-refresh-token');
      expect(refreshed.expiresAt!.isAfter(DateTime.now().toUtc()), isTrue);
      expect(refreshed.firebaseAuthEmulatorHost, emulatorHost);
      expect(await otherStore.get(), withTeam(authenticated, 'team-2'));
      expect(store.writes, 2);
      expect(requests.map((request) => request.method), ['POST', 'GET']);
      expect(logger.errors, isEmpty);
    });
  }

  for (final refresh in [false, true]) {
    test(
      'cancellation preserves the team and credentials: refresh=$refresh',
      () async {
        if (refresh) await expireProfile();
        late List<int> beforeSelection;
        selector = ({required teams, required currentTeamId}) async {
          beforeSelection = await File(store.filePath).readAsBytes();
          return null;
        };

        expect(await run(), 1);

        expect(await File(store.filePath).readAsBytes(), beforeSelection);
        expect((await otherStore.getActiveProfile())!.teamId, 'team-1');
        expect(store.writes, refresh ? 1 : 0);
        expect(logger.output, isEmpty);
        expect(logger.errors, [t.switchCommand.team.cancelled]);
      },
    );

    test(
      'an actual write failure preserves the previous file: refresh=$refresh',
      () async {
        if (refresh) await expireProfile();
        late List<int> beforeSelection;
        selector = ({required teams, required currentTeamId}) async {
          beforeSelection = await File(store.filePath).readAsBytes();
          // Reading still succeeds, but creating the atomic replacement cannot.
          final result = await Process.run('chmod', ['500', root.path]);
          expect(result.exitCode, 0);
          return teams.last;
        };

        try {
          expect(await run(), 1);

          expect(await File(store.filePath).readAsBytes(), beforeSelection);
          expect((await otherStore.getActiveProfile())!.teamId, 'team-1');
          expect(store.writes, refresh ? 2 : 1);
          expect(logger.output, isEmpty);
          expect(logger.errors, [t.switchCommand.team.saveFailed]);
          expect(root.listSync().map((entry) => p.basename(entry.path)), [
            'credentials.json',
          ]);
        } finally {
          final result = await Process.run('chmod', ['700', root.path]);
          expect(result.exitCode, 0);
        }
      },
      skip: permissionTestsSupported
          ? false
          : 'Requires POSIX permissions and an unprivileged user',
    );
  }

  for (final (field, change) in <(String, AuthProfile Function(AuthProfile))>[
    (
      'server URL',
      (value) => value.copyWith(serverUrl: 'https://other.example.com'),
    ),
    ('token', (value) => value.copyWith(token: 'replacement-token')),
    (
      'refresh token',
      (value) => value.copyWith(refreshToken: 'replacement-refresh'),
    ),
    (
      'expiry',
      (value) => value.copyWith(
        expiresAt: value.expiresAt!.add(const Duration(hours: 1)),
      ),
    ),
    ('auth type', (value) => value.copyWith(authType: 'api_key')),
    (
      'Firebase API key',
      (value) => value.copyWith(firebaseApiKey: 'replacement-api-key'),
    ),
    (
      'Auth Emulator',
      (value) => value.copyWith(firebaseAuthEmulatorHost: null),
    ),
    ('team ID', (value) => value.copyWith(teamId: 'concurrent-team')),
  ]) {
    test('refuses to overwrite a concurrent $field change', () async {
      late List<int> changed;
      selector = ({required teams, required currentTeamId}) async {
        await otherStore.saveProfile('selected', change(profile));
        changed = await File(store.filePath).readAsBytes();
        return teams.last;
      };

      expect(await run(), 1);

      expect(await File(store.filePath).readAsBytes(), changed);
      expect(store.writes, 0);
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.switchCommand.team.profileChanged]);
    });
  }

  for (final sameTeam in [false, true]) {
    test(
      'refuses an active profile change even with identical credentials: sameTeam=$sameTeam',
      () async {
        late CredentialConfig changed;
        selector = ({required teams, required currentTeamId}) async {
          changed = initial.copyWith(
            activeProfile: 'another',
            profiles: {...initial.profiles, 'another': profile},
          );
          await otherStore.set(changed);
          return sameTeam ? teams.first : teams.last;
        };

        expect(await run(), 1);

        expect(await otherStore.get(), changed);
        expect(store.writes, 0);
        expect(logger.output, isEmpty);
        expect(logger.errors, [t.switchCommand.team.profileChanged]);
      },
    );
  }

  test('refuses to recreate a profile removed during selection', () async {
    selector = ({required teams, required currentTeamId}) async {
      await otherStore.deleteProfile('selected');
      return teams.last;
    };

    expect(await run(), 1);

    expect(await otherStore.getProfile('selected'), isNull);
    expect(store.writes, 0);
    expect(logger.errors, [t.switchCommand.team.profileChanged]);
  });

  test('preserves unrelated profile edits made during selection', () async {
    late CredentialConfig changed;
    selector = ({required teams, required currentTeamId}) async {
      changed = initial.copyWith(
        profiles: {
          'selected': profile,
          'unused': unused.copyWith(token: 'updated-unused-token'),
          'new': unused.copyWith(teamId: 'new-team'),
        },
      );
      await otherStore.set(changed);
      return teams.last;
    };

    expect(await run(), 0);

    expect(await otherStore.get(), withTeam(changed, 'team-2'));
    expect(store.writes, 1);
    expect(logger.errors, isEmpty);
  });

  test(
    'does not replace malformed credentials created during selection',
    () async {
      selector = ({required teams, required currentTeamId}) async {
        await File(store.filePath).writeAsString('private-token');
        return teams.last;
      };

      expect(await run(), 1);

      expect(await File(store.filePath).readAsString(), 'private-token');
      expect(store.writes, 0);
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.switchCommand.team.saveFailed]);
    },
  );

  test('escapes terminal controls in the success message', () async {
    handler = (_) async => teamsResponse(nextName: 'Next\x1b[2J\nteam');

    expect(await run(), 0);

    expect(logger.output, [
      t.switchCommand.team.success(team: r'Next\x1b[2J\x0ateam (team-2)'),
    ]);
    expect(logger.errors, isEmpty);
  });

  for (final command in ['list', 'sync']) {
    for (final refresh in [false, true]) {
      test(
        '$command secrets reads the newly saved team: refresh=$refresh',
        () async {
          if (refresh) await expireProfile();
          expect(await run(), 0);
          final switched = await File(store.filePath).readAsBytes();
          logger.output.clear();
          requests.clear();
          final workflows = Directory(p.join(root.path, 'project', 'openci'));
          await workflows.create(recursive: true);
          final runner = CommandRunner<int>('genuineci $command', 'test')
            ..addCommand(
              command == 'list'
                  ? ListSecretsCommand(logger: logger, credentialStore: store)
                  : SyncSecretsCommand(
                      logger: logger,
                      credentialStore: store,
                      workingDirectory: workflows.parent,
                    ),
            );

          final result = await http.runWithClient(
            () => runner.run(['secrets']),
            () => MockClient((request) async {
              requests.add(request);
              return http.Response(
                jsonEncode({
                  'success': true,
                  'secrets': [
                    {'name': 'DEPLOY_KEY', 'encryptedValue': 'private-value'},
                  ],
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }),
          );

          expect(result, 0);
          final request = requests.single;
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://ci.example.com/proxy/teams/team-2/secrets',
          );
          expect(
            request.headers['authorization'],
            'Bearer ${refresh ? 'rotated-token' : 'private-token'}',
          );
          expect(await File(store.filePath).readAsBytes(), switched);
          expect(logger.errors, isEmpty);
          if (command == 'list') {
            expect(logger.output, ['DEPLOY_KEY']);
          } else {
            expect(
              await File(
                p.join(workflows.path, 'secrets.g.dart'),
              ).readAsString(),
              contains('DEPLOY_KEY'),
            );
          }
        },
      );
    }
  }
}
