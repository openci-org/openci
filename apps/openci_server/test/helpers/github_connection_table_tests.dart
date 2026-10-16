import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:test/test.dart';

void testGitHubConnectionTable(Future<AppDatabase> Function() openDatabase) {
  late AppDatabase db;

  final connection = GitHubConnectionsCompanion.insert(
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

  setUp(() async {
    db = await openDatabase();
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

  test('stores verified identities, display information, and status', () async {
    await db.into(db.gitHubConnections).insert(connection);

    final saved = await db.select(db.gitHubConnections).getSingle();

    expect(saved.id, 'connection-1');
    expect(saved.teamId, 'team-1');
    expect(saved.githubApiBaseUrl, 'https://api.github.com');
    expect(saved.githubAppId, 4294967296);
    expect(saved.installationId, 4294967297);
    expect(saved.accountId, 4294967298);
    expect(saved.accountType, GitHubAccountType.organization);
    expect(saved.accountLogin, 'openci-org');
    expect(saved.verifiedByUserId, 'user-1');
    expect(saved.verifiedByGitHubUserId, 4294967299);
    expect(saved.verifiedAt.toUtc(), DateTime.utc(2026));
    expect(saved.status, GitHubConnectionStatus.active);
    expect(
      (await db
              .customSelect('SELECT account_type FROM github_connections')
              .getSingle())
          .read<String>('account_type'),
      'Organization',
    );
    final json = jsonDecode(jsonEncode(saved)) as Map<String, dynamic>;
    expect(json['accountType'], 'Organization');
    expect(
      DriftGitHubConnection.fromJson(json).accountType,
      GitHubAccountType.organization,
    );
  });

  test(
    'round-trips a personal account as User in the database and JSON',
    () async {
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              accountType: const Value(GitHubAccountType.user),
              accountLogin: const Value('octocat'),
            ),
          );

      final saved = await db.select(db.gitHubConnections).getSingle();

      expect(saved.accountType, GitHubAccountType.user);
      expect(
        (await db
                .customSelect('SELECT account_type FROM github_connections')
                .getSingle())
            .read<String>('account_type'),
        'User',
      );
      final json = jsonDecode(jsonEncode(saved)) as Map<String, dynamic>;
      expect(json['accountType'], 'User');
      expect(
        DriftGitHubConnection.fromJson(json).accountType,
        GitHubAccountType.user,
      );
    },
  );

  test('rejects an unknown stored account type', () async {
    await db.into(db.gitHubConnections).insert(connection);
    await db.customStatement(
      "UPDATE github_connections SET account_type = 'Bot'",
    );

    await expectLater(
      db.select(db.gitHubConnections).getSingle(),
      throwsFormatException,
    );
  });

  test(
    'does not create verified connections from legacy installation IDs',
    () async {
      expect(await db.select(db.gitHubConnections).get(), isEmpty);
      expect((await db.teamDao.getTeam('team-1'))!.installationIds, [123]);
    },
  );

  test('rejects a duplicate installation in the same team', () async {
    await db.into(db.gitHubConnections).insert(connection);

    await expectLater(
      db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(id: const Value('duplicate')),
          ),
      throwsException,
    );
  });

  test('rejects the same installation in another team', () async {
    await db.into(db.gitHubConnections).insert(connection);

    await expectLater(
      db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: const Value('other-connection'),
              teamId: const Value('team-2'),
              accountLogin: const Value('renamed-org'),
            ),
          ),
      throwsException,
    );
  });

  test('allows another installation in the same team', () async {
    await db.into(db.gitHubConnections).insert(connection);
    await db
        .into(db.gitHubConnections)
        .insert(
          connection.copyWith(
            id: const Value('connection-2'),
            installationId: const Value(200),
          ),
        );

    expect(await db.select(db.gitHubConnections).get(), hasLength(2));
  });

  test(
    'keeps matching installation IDs on different GitHub hosts separate',
    () async {
      await db.into(db.gitHubConnections).insert(connection);
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: const Value('enterprise-connection'),
              teamId: const Value('team-2'),
              githubApiBaseUrl: const Value(
                'https://github.example.com/api/v3',
              ),
            ),
          );

      expect(await db.select(db.gitHubConnections).get(), hasLength(2));
    },
  );

  test(
    'keeps matching installation IDs for different GitHub Apps separate',
    () async {
      await db.into(db.gitHubConnections).insert(connection);
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: const Value('other-app-connection'),
              teamId: const Value('team-2'),
              githubAppId: const Value(200),
            ),
          );

      expect(await db.select(db.gitHubConnections).get(), hasLength(2));
    },
  );

  test('rejects a connection for a missing team', () async {
    await expectLater(
      db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(teamId: const Value('missing-team')),
          ),
      throwsException,
    );
  });

  test('deleting a team removes only its connections', () async {
    await db.into(db.gitHubConnections).insert(connection);
    await db
        .into(db.gitHubConnections)
        .insert(
          connection.copyWith(
            id: const Value('other-team-connection'),
            teamId: const Value('team-2'),
            installationId: const Value(200),
          ),
        );

    await (db.delete(db.teams)..where((team) => team.id.equals('team-1'))).go();

    final remaining = await db.select(db.gitHubConnections).getSingle();
    expect(remaining.id, 'other-team-connection');
    expect(remaining.teamId, 'team-2');
  });

  test('suspending a connection keeps it assigned to its team', () async {
    await db.into(db.gitHubConnections).insert(connection);
    await (db.update(
      db.gitHubConnections,
    )..where((table) => table.id.equals('connection-1'))).write(
      const GitHubConnectionsCompanion(
        status: Value(GitHubConnectionStatus.suspended),
      ),
    );

    final saved = await db.select(db.gitHubConnections).getSingle();
    expect(saved.status, GitHubConnectionStatus.suspended);
    await expectLater(
      db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: const Value('other-connection'),
              teamId: const Value('team-2'),
            ),
          ),
      throwsException,
    );
  });

  test('removing a connection does not free it for another team', () async {
    await db
        .into(db.gitHubConnections)
        .insert(
          connection.copyWith(
            status: const Value(GitHubConnectionStatus.removed),
          ),
        );

    final saved = await db.select(db.gitHubConnections).getSingle();
    expect(saved.status, GitHubConnectionStatus.removed);
    await expectLater(
      db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: const Value('other-connection'),
              teamId: const Value('team-2'),
            ),
          ),
      throwsException,
    );
  });
}
