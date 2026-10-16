import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/create_github_connection_request.dart';
import 'package:openci_server/github/create_github_connection_session.dart';
import 'package:openci_server/github/github_connection_session_table.dart';
import 'package:openci_server/github/read_github_connection_session.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  const sessionReference = 'connection-session-reference';
  final createdAt = DateTime.utc(2026, 10, 16, 12);
  final expiresAt = createdAt.add(const Duration(minutes: 10));
  final session = GitHubConnectionSessionsCompanion.insert(
    id: 'session-1',
    userId: 'user-1',
    teamId: 'team-1',
    githubUserId: 123,
    referenceHash: sha256.convert(utf8.encode(sessionReference)).toString(),
    encryptedAccessToken: const Value('encrypted-user-token'),
    createdAt: createdAt,
    expiresAt: expiresAt,
  );

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [],
        aiEnabled: false,
        runNumber: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      'user-1',
    );
    await db.teamDao.addTeamMember('team-1', 'teammate');
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-2',
        name: 'Other team',
        installationIds: const [],
        aiEnabled: false,
        runNumber: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      'user-1',
    );
    await db.into(db.gitHubConnectionSessions).insert(session);
  });

  tearDown(() => db.close());

  Future<DriftGitHubConnectionSession?> read({
    String reference = sessionReference,
    String userId = 'user-1',
    String teamId = 'team-1',
    DateTime? now,
  }) => readGitHubConnectionSession(
    db: db,
    reference: reference,
    userId: userId,
    teamId: teamId,
    now: now ?? createdAt,
  );

  test('returns an active session to its initiating team member', () async {
    final result = await read(
      now: expiresAt.subtract(const Duration(seconds: 1)),
    );

    expect(result, isNotNull);
    expect(result!.id, 'session-1');
    expect(result.userId, 'user-1');
    expect(result.teamId, 'team-1');
    expect(result.githubUserId, 123);
    expect(result.encryptedAccessToken, 'encrypted-user-token');
    expect(result.expiresAt.toUtc(), expiresAt);
  });

  test('rejects another member of the same team', () async {
    expect(await read(userId: 'teammate'), isNull);
  });

  test(
    'rejects another team even when the initiator belongs to both',
    () async {
      expect(await read(teamId: 'team-2'), isNull);
    },
  );

  test('rejects an initiator who has left the team', () async {
    await (db.delete(db.teamMembers)..where(
          (member) =>
              member.userId.equals('user-1') & member.teamId.equals('team-1'),
        ))
        .go();

    expect(await read(), isNull);
  });

  test('rejects an unknown reference', () async {
    expect(await read(reference: 'unknown-reference'), isNull);
  });

  test('does not accept the stored hash as the original reference', () async {
    expect(await read(reference: session.referenceHash.value), isNull);
  });

  test('does not accept the pre-authorization state or request ID', () async {
    final request = await createGitHubConnectionRequest(
      db: db,
      userId: 'user-1',
      teamId: 'team-1',
      now: createdAt,
    );

    expect(await read(reference: request.state), isNull);
    expect(await read(reference: request.id), isNull);
  });

  test('rejects a session after it expires', () async {
    expect(await read(now: expiresAt.add(const Duration(seconds: 1))), isNull);
  });

  test('rejects a session at its exact expiration time', () async {
    expect(await read(now: expiresAt), isNull);
  });

  test('rejects a consumed session even when its token remains', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          GitHubConnectionSessionsCompanion(consumedAt: Value(createdAt)),
        );

    expect(await read(), isNull);
  });

  test('rejects a session whose token has been cleared', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          const GitHubConnectionSessionsCompanion(
            encryptedAccessToken: Value(null),
          ),
        );

    expect(await read(), isNull);
  });

  test(
    'allows repeated reads without consuming or changing the session',
    () async {
      final before = await db
          .customSelect('SELECT * FROM github_connection_sessions')
          .getSingle();

      expect((await read())?.id, 'session-1');
      expect((await read())?.id, 'session-1');

      final after = await db
          .customSelect('SELECT * FROM github_connection_sessions')
          .getSingle();
      expect(after.data, before.data);
    },
  );

  test('reads a newly created session using the current time', () async {
    final crypter = SecretCrypter(base64Encode(List<int>.filled(32, 1)));
    final created = await createGitHubConnectionSession(
      db: db,
      crypter: crypter,
      userId: 'user-1',
      teamId: 'team-1',
      githubUserId: 456,
      accessToken: 'new-github-token',
    );

    final result = await readGitHubConnectionSession(
      db: db,
      reference: created.reference,
      userId: 'user-1',
      teamId: 'team-1',
    );

    expect(result?.githubUserId, 456);
    expect(
      await crypter.decrypt(result!.encryptedAccessToken!),
      'new-github-token',
    );
  });

  test('reports database failures without exposing query values', () async {
    await db.customStatement('DROP TABLE github_connection_sessions');

    await expectLater(
      read(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Failed to read GitHub connection session',
        ),
      ),
    );
  });
}
