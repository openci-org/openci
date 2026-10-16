import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:openci_server/database.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/save_github_connection.dart';
import 'package:openci_server/github/save_github_connection_and_consume_session.dart';
import 'package:test/test.dart';

void testSaveGitHubConnectionAndConsumeSession(
  Future<AppDatabase> Function() openDatabase, {
  Future<AppDatabase> Function()? openConcurrentDatabase,
}) {
  late AppDatabase db;
  late DateTime verifiedAt;
  const reference = 'connection-session-reference';
  const installation = GitHubInstallation(
    id: 100,
    appId: 200,
    accountId: 300,
    accountType: 'Organization',
    accountLogin: 'openci-org',
    suspendedAt: null,
  );
  const anotherInstallation = GitHubInstallation(
    id: 101,
    appId: 200,
    accountId: 301,
    accountType: 'Organization',
    accountLogin: 'another-org',
    suspendedAt: null,
  );

  setUp(() async {
    db = await openDatabase();
    verifiedAt = DateTime.now().toUtc();
    final team = DriftTeam(
      id: 'team-1',
      name: 'OpenCI',
      installationIds: const [],
      aiEnabled: false,
      runNumber: 1,
      createdAt: verifiedAt,
      updatedAt: verifiedAt,
    );
    await db.teamDao.createTeamAndMember(team, 'user-1');
    await db.teamDao.addTeamMember('team-1', 'teammate');
    await db.into(db.teams).insert(team.copyWith(id: 'team-2'));
    await db
        .into(db.gitHubConnectionSessions)
        .insert(
          GitHubConnectionSessionsCompanion.insert(
            id: 'session-1',
            userId: 'user-1',
            teamId: 'team-1',
            githubUserId: 123,
            referenceHash: sha256.convert(utf8.encode(reference)).toString(),
            encryptedAccessToken: const Value('encrypted-user-token'),
            createdAt: verifiedAt,
            expiresAt: verifiedAt.add(const Duration(minutes: 10)),
          ),
        );
  });

  tearDown(() => db.close());

  Future<DriftGitHubConnection?> saveAndConsume({
    AppDatabase? database,
    String userId = 'user-1',
    GitHubInstallation verifiedInstallation = installation,
  }) => saveGitHubConnectionAndConsumeSession(
    db: database ?? db,
    reference: reference,
    teamId: 'team-1',
    githubApiBaseUrl: 'https://api.github.com',
    verifiedInstallation: verifiedInstallation,
    verifiedByUserId: userId,
    verifiedByGitHubUserId: 123,
    verifiedAt: verifiedAt,
  );

  Future<DriftGitHubConnection> seedConnection({
    String teamId = 'team-1',
  }) async => (await saveGitHubConnection(
    db: db,
    teamId: teamId,
    githubApiBaseUrl: 'https://api.github.com',
    verifiedInstallation: installation,
    verifiedByUserId: 'previous-verifier',
    verifiedByGitHubUserId: 456,
    verifiedAt: verifiedAt.subtract(const Duration(days: 1)),
  ))!;

  Future<void> expectUnconsumedSession() async {
    final session = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(session.consumedAt, isNull);
    expect(session.encryptedAccessToken, 'encrypted-user-token');
  }

  final invalidSession = throwsA(
    isA<InvalidGitHubConnectionSessionException>(),
  );
  final databaseFailure = throwsA(
    isA<StateError>().having(
      (error) => error.message,
      'message',
      'Failed to save GitHub connection and consume session',
    ),
  );

  test('saves the connection and consumes the session together', () async {
    final connection = await saveAndConsume();

    expect(connection, isNotNull);
    expect(await db.select(db.gitHubConnections).getSingle(), connection);
    expect(connection!.teamId, 'team-1');
    expect(connection.verifiedByUserId, 'user-1');
    expect(connection.verifiedByGitHubUserId, 123);
    final session = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(session.consumedAt, isNotNull);
    expect(session.encryptedAccessToken, isNull);
  });

  test('refreshes a same-team connection and consumes the session', () async {
    final original = await seedConnection();

    final connection = (await saveAndConsume())!;

    expect(connection.id, original.id);
    expect(connection.verifiedByUserId, 'user-1');
    expect(connection.verifiedByGitHubUserId, 123);
    expect(await db.select(db.gitHubConnections).getSingle(), connection);
    final session = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(session.consumedAt, isNotNull);
    expect(session.encryptedAccessToken, isNull);
  });

  test('leaves the session unused on an ownership conflict', () async {
    final original = await seedConnection(teamId: 'team-2');

    expect(await saveAndConsume(), isNull);

    expect(await db.select(db.gitHubConnections).getSingle(), original);
    await expectUnconsumedSession();
  });

  test('rolls back insertion when the session has expired', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          GitHubConnectionSessionsCompanion(
            expiresAt: Value(verifiedAt.subtract(const Duration(seconds: 1))),
          ),
        );

    await expectLater(saveAndConsume(), invalidSession);

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnconsumedSession();
  });

  test('rolls back a refresh when the session has already been used', () async {
    final original = await seedConnection();
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          GitHubConnectionSessionsCompanion(
            consumedAt: Value(verifiedAt),
            encryptedAccessToken: const Value(null),
          ),
        );

    await expectLater(saveAndConsume(), invalidSession);

    expect(await db.select(db.gitHubConnections).getSingle(), original);
  });

  test('rejects another member without saving or consuming', () async {
    await expectLater(saveAndConsume(userId: 'teammate'), invalidSession);

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnconsumedSession();
  });

  test('does not reuse one session to save a different installation', () async {
    final original = await saveAndConsume();

    await expectLater(
      saveAndConsume(verifiedInstallation: anotherInstallation),
      invalidSession,
    );

    expect(await db.select(db.gitHubConnections).getSingle(), original);
  });

  test('leaves the session unused when saving fails', () async {
    await db.customStatement('DROP TABLE github_connections');

    await expectLater(saveAndConsume(), databaseFailure);

    await expectUnconsumedSession();
  });

  test(
    'rolls back the save when consuming fails with a database error',
    () async {
      await db.customStatement('DROP TABLE github_connection_sessions');

      await expectLater(saveAndConsume(), databaseFailure);

      expect(await db.select(db.gitHubConnections).get(), isEmpty);
    },
  );

  test('rolls back both changes when the caller transaction fails', () async {
    final failure = StateError('Caller transaction failed');

    await expectLater(
      db.transaction(() async {
        expect(await saveAndConsume(), isNotNull);
        throw failure;
      }),
      throwsA(same(failure)),
    );

    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnconsumedSession();
  });

  if (openConcurrentDatabase != null) {
    test(
      'only one independent connection can save using the session',
      () async {
        final other = await openConcurrentDatabase();
        addTearDown(other.close);
        await other.select(other.gitHubConnections).get();

        Future<Object?> attempt(
          AppDatabase database,
          GitHubInstallation candidate,
        ) async {
          try {
            return await saveAndConsume(
              database: database,
              verifiedInstallation: candidate,
            );
          } on InvalidGitHubConnectionSessionException catch (error) {
            return error;
          }
        }

        final results = await Future.wait([
          attempt(db, installation),
          attempt(other, anotherInstallation),
        ]);

        final saved = await db.select(db.gitHubConnections).getSingle();
        expect(results.whereType<DriftGitHubConnection>(), [saved]);
        expect(
          results.whereType<InvalidGitHubConnectionSessionException>(),
          hasLength(1),
        );
        final session = await db
            .select(db.gitHubConnectionSessions)
            .getSingle();
        expect(session.consumedAt, isNotNull);
        expect(session.encryptedAccessToken, isNull);
      },
    );
  }
}
