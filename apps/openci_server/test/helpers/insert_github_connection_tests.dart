import 'package:openci_server/database.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_server/github/insert_github_connection.dart';
import 'package:test/test.dart';

void testInsertGitHubConnection(Future<AppDatabase> Function() openDatabase) {
  late AppDatabase db;
  final verifiedAt = DateTime(2026, 10, 17, 10, 2, 3);

  GitHubInstallation installation({
    int id = 4294967297,
    int accountId = 4294967298,
    String accountType = 'Organization',
    String accountLogin = 'openci-org',
    DateTime? suspendedAt,
  }) => GitHubInstallation(
    id: id,
    appId: 4294967296,
    accountId: accountId,
    accountType: accountType,
    accountLogin: accountLogin,
    suspendedAt: suspendedAt,
  );

  Future<DriftGitHubConnection> insert({
    String teamId = 'team-1',
    String githubApiBaseUrl = 'https://api.github.com',
    GitHubInstallation? verifiedInstallation,
  }) => insertGitHubConnection(
    db: db,
    teamId: teamId,
    githubApiBaseUrl: githubApiBaseUrl,
    verifiedInstallation: verifiedInstallation ?? installation(),
    verifiedByUserId: 'user-1',
    verifiedByGitHubUserId: 4294967299,
    verifiedAt: verifiedAt,
  );

  final insertFailure = throwsA(
    isA<StateError>().having(
      (error) => error.message,
      'message',
      'Failed to insert GitHub connection',
    ),
  );

  setUp(() async {
    db = await openDatabase();
    final team = DriftTeam(
      id: 'team-1',
      name: 'OpenCI',
      installationIds: const [],
      aiEnabled: false,
      runNumber: 1,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await db.into(db.teams).insert(team);
    await db.into(db.teams).insert(team.copyWith(id: 'team-2'));
  });

  tearDown(() => db.close());

  test('stores verified metadata with a canonical GHES URL', () async {
    final result = await insert(
      githubApiBaseUrl: ' https://github.example:8443/github/api/v3/// ',
    );

    final saved = await db.select(db.gitHubConnections).getSingle();
    expect(result, saved);
    expect(saved.id, isNotEmpty);
    expect(saved.teamId, 'team-1');
    expect(saved.githubApiBaseUrl, 'https://github.example:8443/github/api/v3');
    expect(saved.githubAppId, 4294967296);
    expect(saved.installationId, 4294967297);
    expect(saved.accountId, 4294967298);
    expect(saved.accountType, GitHubAccountType.organization);
    expect(saved.accountLogin, 'openci-org');
    expect(saved.verifiedByUserId, 'user-1');
    expect(saved.verifiedByGitHubUserId, 4294967299);
    expect(saved.verifiedAt.toUtc(), verifiedAt.toUtc());
    expect(saved.status, GitHubConnectionStatus.active);
  });

  test('adds a personal installation with an independent record ID', () async {
    final first = await insert();
    final second = await insert(
      verifiedInstallation: installation(
        id: 200,
        accountId: 4294967299,
        accountType: 'User',
        accountLogin: 'octocat',
      ),
    );

    final saved = await db.select(db.gitHubConnections).get();
    expect(saved, unorderedEquals([first, second]));
    expect(second.id, isNot(first.id));
    expect(second.accountType, GitHubAccountType.user);
    expect(second.accountLogin, 'octocat');
  });

  test('rejects a suspended installation before saving', () async {
    await expectLater(
      insert(verifiedInstallation: installation(suspendedAt: verifiedAt)),
      throwsArgumentError,
    );

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
  });

  test('rejects an unsupported account type before saving', () async {
    await expectLater(
      insert(verifiedInstallation: installation(accountType: 'Bot')),
      throwsFormatException,
    );

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
  });

  test('rejects an invalid API URL before saving', () async {
    await expectLater(
      insert(githubApiBaseUrl: 'https://user:private@api.github.com'),
      throwsStateError,
    );

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
  });

  test('rejects a missing team without exposing database errors', () async {
    await expectLater(insert(teamId: 'missing-team'), insertFailure);

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
  });

  for (final teamId in ['team-1', 'team-2']) {
    test('a duplicate for $teamId leaves the existing row intact', () async {
      final original = await insert();

      await expectLater(
        insert(
          teamId: teamId,
          githubApiBaseUrl: ' https://api.github.com/// ',
          verifiedInstallation: installation(accountLogin: 'renamed-org'),
        ),
        insertFailure,
      );

      expect(await db.select(db.gitHubConnections).getSingle(), original);
    });
  }

  test('participates in a caller transaction rollback', () async {
    final rollback = StateError('Roll back the connection');
    await expectLater(
      db.transaction(() async {
        await insert();
        throw rollback;
      }),
      throwsA(same(rollback)),
    );

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    final retried = await insert();
    expect(await db.select(db.gitHubConnections).getSingle(), retried);
  });
}
