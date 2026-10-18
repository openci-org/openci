import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:test/test.dart';

void testGetTeamByInstallationId(Future<AppDatabase> Function() openDatabase) {
  late AppDatabase db;

  final connection = DriftGitHubConnection(
    id: 'connection-1',
    teamId: 'team-1',
    githubApiBaseUrl: 'https://api.github.com',
    githubAppId: 4294967296,
    installationId: 4294967297,
    accountId: 42,
    accountType: GitHubAccountType.organization,
    accountLogin: 'openci-org',
    verifiedByUserId: 'member-1',
    verifiedByGitHubUserId: 100,
    verifiedAt: DateTime.utc(2026),
    status: GitHubConnectionStatus.active,
  );

  Future<DriftTeam?> read({int installationId = 4294967297}) =>
      db.teamDao.getTeamByInstallationId(
        installationId,
        githubApiBaseUrl: 'https://api.github.com',
        githubAppId: 4294967296,
      );

  setUp(() async {
    db = await openDatabase();
    final team = DriftTeam(
      id: 'team-1',
      name: 'OpenCI',
      installationIds: const [],
      aiEnabled: false,
      runNumber: 42,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await db
        .into(db.teams)
        .insert(
          team.copyWith(id: 'other-team', installationIds: [4294967297]),
        );
    await db.into(db.teams).insert(team);
  });

  tearDown(() => db.close());

  test('resolves the verified owner instead of a legacy owner', () async {
    await db.into(db.gitHubConnections).insert(connection);

    final team = await read();

    expect(team?.id, 'team-1');
    expect(team?.installationIds, isEmpty);
  });

  test('does not resolve an installation with only legacy links', () async {
    expect(await read(), isNull);
  });

  test('does not resolve an unknown installation', () async {
    await db.into(db.gitHubConnections).insert(connection);

    expect(await read(installationId: 123), isNull);
  });

  test('excludes suspended and removed connections', () async {
    await db
        .into(db.gitHubConnections)
        .insert(
          connection.copyWith(status: GitHubConnectionStatus.suspended),
        );
    await db
        .into(db.gitHubConnections)
        .insert(
          connection.copyWith(
            id: 'removed-connection',
            installationId: 123,
            status: GitHubConnectionStatus.removed,
          ),
        );

    expect(await read(), isNull);
    expect(await read(installationId: 123), isNull);
  });

  test(
    'does not resolve the same installation ID for another host or App',
    () async {
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: 'other-host',
              teamId: 'other-team',
              githubApiBaseUrl: 'https://github.example/api/v3',
            ),
          );
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: 'other-app',
              teamId: 'other-team',
              githubAppId: 42,
            ),
          );

      expect(await read(), isNull);

      await db.into(db.gitHubConnections).insert(connection);
      expect((await read())?.id, 'team-1');
    },
  );

  test(
    'propagates database failures instead of treating them as no match',
    () async {
      await db.customStatement('DROP TABLE github_connections');

      await expectLater(read(), throwsException);
    },
  );
}
