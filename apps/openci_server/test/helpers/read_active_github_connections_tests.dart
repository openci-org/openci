import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_server/github/read_active_github_connections.dart';
import 'package:test/test.dart';

void testReadActiveGitHubConnections(
  Future<AppDatabase> Function() openDatabase,
) {
  late AppDatabase db;
  late Map<String, String> environment;

  final connection = DriftGitHubConnection(
    id: 'connection-1',
    teamId: 'team-1',
    githubApiBaseUrl: 'https://api.github.com',
    githubAppId: 4294967296,
    installationId: 4294967297,
    accountId: 4294967298,
    accountType: GitHubAccountType.organization,
    accountLogin: 'openci-org',
    verifiedByUserId: 'user-1',
    verifiedByGitHubUserId: 4294967299,
    verifiedAt: DateTime.utc(2026),
    status: GitHubConnectionStatus.active,
  );

  Future<List<DriftGitHubConnection>> read({String teamId = 'team-1'}) =>
      readActiveGitHubConnections(
        db: db,
        teamId: teamId,
        environment: environment,
      );

  setUp(() async {
    db = await openDatabase();
    environment = {
      'GITHUB_API_BASE_URL': 'https://api.github.com',
      'GITHUB_APP_ID': '4294967296',
    };
    final team = DriftTeam(
      id: 'team-1',
      name: 'OpenCI',
      installationIds: const [123],
      aiEnabled: false,
      runNumber: 1,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await db.into(db.teams).insert(team);
    await db.into(db.teams).insert(team.copyWith(id: 'team-2'));
  });

  tearDown(() => db.close());

  test(
    'returns all active connections matching the team and operator',
    () async {
      await db.into(db.gitHubConnections).insert(connection);
      await db
          .into(db.gitHubConnections)
          .insert(connection.copyWith(id: 'connection-2', installationId: 200));

      final connections = await read();

      expect(
        connections.map((connection) => connection.installationId),
        unorderedEquals([4294967297, 200]),
      );
    },
  );

  test('excludes connections owned by another team', () async {
    await db
        .into(db.gitHubConnections)
        .insert(connection.copyWith(teamId: 'team-2'));

    expect(await read(), isEmpty);
    expect((await read(teamId: 'team-2')).single.id, connection.id);
  });

  test('excludes suspended and removed connections', () async {
    await db
        .into(db.gitHubConnections)
        .insert(connection.copyWith(status: GitHubConnectionStatus.suspended));
    await db
        .into(db.gitHubConnections)
        .insert(
          connection.copyWith(
            id: 'removed-connection',
            installationId: 200,
            status: GitHubConnectionStatus.removed,
          ),
        );

    expect(await read(), isEmpty);
  });

  test('excludes connections for a different GitHub API host', () async {
    await db
        .into(db.gitHubConnections)
        .insert(
          connection.copyWith(
            githubApiBaseUrl: 'https://github.example/api/v3',
          ),
        );

    expect(await read(), isEmpty);
  });

  test('excludes connections for a different GitHub App', () async {
    await db
        .into(db.gitHubConnections)
        .insert(connection.copyWith(githubAppId: 42));

    expect(await read(), isEmpty);
  });

  test(
    'normalizes the configured URL and preserves the API path and port',
    () async {
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              githubApiBaseUrl: 'https://github.example:8443/github/api/v3',
            ),
          );
      environment['GITHUB_API_BASE_URL'] =
          ' https://github.example:8443/github/api/v3/// ';

      expect((await read()).single.id, connection.id);

      environment['GITHUB_API_BASE_URL'] = 'https://github.example:8443/api/v3';
      expect(await read(), isEmpty);
      environment['GITHUB_API_BASE_URL'] =
          'https://github.example/github/api/v3';
      expect(await read(), isEmpty);
    },
  );

  test('does not fall back to legacy installation IDs', () async {
    expect((await db.teamDao.getTeam('team-1'))!.installationIds, [123]);
    expect(await read(), isEmpty);
  });

  test('returns no connections for an unknown team', () async {
    await db.into(db.gitHubConnections).insert(connection);

    expect(await read(teamId: 'missing-team'), isEmpty);
  });

  test('rejects a missing GitHub API URL', () async {
    environment.remove('GITHUB_API_BASE_URL');

    await expectLater(read(), throwsStateError);
  });

  test('rejects a missing GitHub App ID', () async {
    environment.remove('GITHUB_APP_ID');

    await expectLater(read(), throwsStateError);
  });

  test('rejects an invalid GitHub App ID without exposing its value', () async {
    environment['GITHUB_APP_ID'] = 'private-invalid-app-id';

    await expectLater(
      read(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'GITHUB_APP_ID must be a positive integer',
        ),
      ),
    );
  });

  test('rejects a non-positive GitHub App ID', () async {
    environment['GITHUB_APP_ID'] = '0';

    await expectLater(read(), throwsStateError);
    environment['GITHUB_APP_ID'] = '-1';
    await expectLater(read(), throwsStateError);
  });

  test('does not treat a database failure as an empty result', () async {
    await db.customStatement('DROP TABLE github_connections');

    await expectLater(
      read(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Failed to read GitHub connections',
        ),
      ),
    );
  });
}
