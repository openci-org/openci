import 'package:drift/drift.dart' show Value;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_server/github/save_github_connection.dart';
import 'package:test/test.dart';

void testSaveGitHubConnection(
  Future<AppDatabase> Function() openDatabase, {
  Future<AppDatabase> Function()? openConcurrentDatabase,
}) {
  late AppDatabase db;
  final verifiedAt = DateTime(2026, 10, 17, 10, 2, 3);

  GitHubInstallation installation({
    int id = 4294967297,
    int appId = 4294967296,
    int accountId = 4294967298,
    String accountType = 'Organization',
    String accountLogin = 'openci-org',
    DateTime? suspendedAt,
  }) => GitHubInstallation(
    id: id,
    appId: appId,
    accountId: accountId,
    accountType: accountType,
    accountLogin: accountLogin,
    suspendedAt: suspendedAt,
  );

  Future<DriftGitHubConnection?> save({
    AppDatabase? database,
    String teamId = 'team-1',
    String githubApiBaseUrl = 'https://api.github.com',
    GitHubInstallation? verifiedInstallation,
    String verifiedByUserId = 'user-1',
    int verifiedByGitHubUserId = 4294967299,
    DateTime? verificationTime,
  }) => saveGitHubConnection(
    db: database ?? db,
    teamId: teamId,
    githubApiBaseUrl: githubApiBaseUrl,
    verifiedInstallation: verifiedInstallation ?? installation(),
    verifiedByUserId: verifiedByUserId,
    verifiedByGitHubUserId: verifiedByGitHubUserId,
    verifiedAt: verificationTime ?? verifiedAt,
  );

  final saveFailure = throwsA(
    isA<StateError>().having(
      (error) => error.message,
      'message',
      'Failed to save GitHub connection',
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
    final result = await save(
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
    final first = (await save())!;
    final second = (await save(
      verifiedInstallation: installation(
        id: 200,
        accountId: 4294967299,
        accountType: 'User',
        accountLogin: 'octocat',
      ),
    ))!;

    final saved = await db.select(db.gitHubConnections).get();
    expect(saved, unorderedEquals([first, second]));
    expect(second.id, isNot(first.id));
    expect(second.accountType, GitHubAccountType.user);
    expect(second.accountLogin, 'octocat');
  });

  test('rejects a suspended installation before saving', () async {
    await expectLater(
      save(verifiedInstallation: installation(suspendedAt: verifiedAt)),
      throwsArgumentError,
    );

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
  });

  test('rejects an unsupported account type before saving', () async {
    await expectLater(
      save(verifiedInstallation: installation(accountType: 'Bot')),
      throwsFormatException,
    );

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
  });

  test('rejects an invalid API URL before saving', () async {
    await expectLater(
      save(githubApiBaseUrl: 'https://user:private@api.github.com'),
      throwsStateError,
    );

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
  });

  test('rejects a missing team without exposing database errors', () async {
    await expectLater(save(teamId: 'missing-team'), saveFailure);

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
  });

  for (final status in GitHubConnectionStatus.values) {
    Future<DriftGitHubConnection> seedConnection() async {
      await save();
      await db
          .update(db.gitHubConnections)
          .write(
            GitHubConnectionsCompanion(status: Value(status)),
          );
      return db.select(db.gitHubConnections).getSingle();
    }

    test('refreshes a $status connection owned by the same team', () async {
      final original = await seedConnection();
      final refreshedAt = verifiedAt.add(const Duration(minutes: 1));
      final refreshed = (await save(
        githubApiBaseUrl: ' https://api.github.com/// ',
        verifiedInstallation: installation(accountLogin: 'renamed-org'),
        verifiedByUserId: 'user-2',
        verifiedByGitHubUserId: 42,
        verificationTime: refreshedAt,
      ))!;

      expect(refreshed.id, original.id);
      expect(refreshed.teamId, original.teamId);
      expect(refreshed.githubApiBaseUrl, original.githubApiBaseUrl);
      expect(refreshed.githubAppId, original.githubAppId);
      expect(refreshed.installationId, original.installationId);
      expect(refreshed.accountId, original.accountId);
      expect(refreshed.accountType, original.accountType);
      expect(refreshed.accountLogin, 'renamed-org');
      expect(refreshed.verifiedByUserId, 'user-2');
      expect(refreshed.verifiedByGitHubUserId, 42);
      expect(refreshed.verifiedAt.toUtc(), refreshedAt.toUtc());
      expect(refreshed.status, GitHubConnectionStatus.active);
      expect(await db.select(db.gitHubConnections).getSingle(), refreshed);
    });

    test('keeps a $status connection owned by another team intact', () async {
      final original = await seedConnection();

      final result = await save(
        teamId: 'team-2',
        githubApiBaseUrl: ' https://api.github.com/// ',
        verifiedInstallation: installation(accountLogin: 'renamed-org'),
      );

      expect(result, isNull);
      expect(await db.select(db.gitHubConnections).getSingle(), original);
    });
  }

  test('a same-team retry returns the existing record', () async {
    final original = (await save())!;

    expect(await save(), original);
    expect(await db.select(db.gitHubConnections).getSingle(), original);
  });

  for (final differentHost in [true, false]) {
    test(
      'keeps a different ${differentHost ? 'host' : 'app'} separate',
      () async {
        final original = (await save())!;
        final separate = (await save(
          teamId: 'team-2',
          githubApiBaseUrl: differentHost
              ? 'https://github.example/api/v3'
              : 'https://api.github.com',
          verifiedInstallation: installation(
            appId: differentHost ? 4294967296 : 200,
          ),
        ))!;

        expect(separate.id, isNot(original.id));
        expect(separate.teamId, 'team-2');
        expect(
          await db.select(db.gitHubConnections).get(),
          unorderedEquals([original, separate]),
        );
      },
    );
  }

  test('rolls back a refresh when the caller transaction fails', () async {
    final original = (await save())!;
    final rollback = StateError('Roll back the refresh');
    await expectLater(
      db.transaction(() async {
        final refreshed = await save(
          verifiedInstallation: installation(accountLogin: 'renamed-org'),
        );
        expect(refreshed!.accountLogin, 'renamed-org');
        throw rollback;
      }),
      throwsA(same(rollback)),
    );

    expect(await db.select(db.gitHubConnections).getSingle(), original);
  });

  test('participates in a caller transaction rollback', () async {
    final rollback = StateError('Roll back the connection');
    await expectLater(
      db.transaction(() async {
        await save();
        throw rollback;
      }),
      throwsA(same(rollback)),
    );

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    final retried = await save();
    expect(await db.select(db.gitHubConnections).getSingle(), retried);
  });

  if (openConcurrentDatabase != null) {
    for (final sameTeam in [true, false]) {
      test(
        'concurrent saves for ${sameTeam ? 'one team' : 'two teams'}',
        () async {
          final other = await openConcurrentDatabase();
          addTearDown(other.close);
          await other.select(other.gitHubConnections).get();

          final results = await Future.wait([
            save(),
            save(database: other, teamId: sameTeam ? 'team-1' : 'team-2'),
          ]);

          final saved = await db.select(db.gitHubConnections).getSingle();
          final successful = results
              .whereType<DriftGitHubConnection>()
              .toList();
          expect(successful, hasLength(sameTeam ? 2 : 1));
          expect(successful.every((result) => result == saved), isTrue);
          if (!sameTeam) {
            expect(results.where((result) => result == null), hasLength(1));
          }
        },
      );
    }
  }
}
