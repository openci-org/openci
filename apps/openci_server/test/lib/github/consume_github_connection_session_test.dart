import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/consume_github_connection_session.dart';
import 'package:openci_server/github/create_github_connection_session.dart';
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

  Future<bool> consume({
    String reference = sessionReference,
    String userId = 'user-1',
    String teamId = 'team-1',
    DateTime? now,
  }) => consumeGitHubConnectionSession(
    db: db,
    reference: reference,
    userId: userId,
    teamId: teamId,
    now: now ?? createdAt,
  );

  Future<void> expectUnconsumedSession() async {
    final saved = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(saved.consumedAt, isNull);
    expect(saved.encryptedAccessToken, 'encrypted-user-token');
  }

  test(
    'marks only the matching session consumed and clears its token',
    () async {
      await db
          .into(db.gitHubConnectionSessions)
          .insert(
            session.copyWith(
              id: const Value('other-session'),
              referenceHash: const Value('other-reference-hash'),
            ),
          );
      final consumedAt = expiresAt.subtract(const Duration(seconds: 1));

      expect(await consume(now: consumedAt), isTrue);

      final consumed = await (db.select(
        db.gitHubConnectionSessions,
      )..where((table) => table.id.equals('session-1'))).getSingle();
      expect(consumed.consumedAt?.toUtc(), consumedAt);
      expect(consumed.encryptedAccessToken, isNull);
      expect(consumed.userId, 'user-1');
      expect(consumed.teamId, 'team-1');
      expect(consumed.githubUserId, 123);
      expect(consumed.referenceHash, session.referenceHash.value);
      expect(consumed.createdAt.toUtc(), createdAt);
      expect(consumed.expiresAt.toUtc(), expiresAt);

      final other = await (db.select(
        db.gitHubConnectionSessions,
      )..where((table) => table.id.equals('other-session'))).getSingle();
      expect(other.consumedAt, isNull);
      expect(other.encryptedAccessToken, 'encrypted-user-token');
      expect(
        await readGitHubConnectionSession(
          db: db,
          reference: sessionReference,
          userId: 'user-1',
          teamId: 'team-1',
          now: consumedAt,
        ),
        isNull,
      );
    },
  );

  test(
    'rejects another member of the same team without changing the session',
    () async {
      expect(await consume(userId: 'teammate'), isFalse);
      await expectUnconsumedSession();
    },
  );

  test(
    'rejects another team even when the initiator belongs to both',
    () async {
      expect(await consume(teamId: 'team-2'), isFalse);
      await expectUnconsumedSession();
    },
  );

  test('rejects an initiator who has left the team', () async {
    await (db.delete(db.teamMembers)..where(
          (member) =>
              member.userId.equals('user-1') & member.teamId.equals('team-1'),
        ))
        .go();

    expect(await consume(), isFalse);
    await expectUnconsumedSession();
  });

  test('rejects an unknown reference without changing the session', () async {
    expect(await consume(reference: 'unknown-reference'), isFalse);
    await expectUnconsumedSession();
  });

  test('does not accept the stored hash as the original reference', () async {
    expect(await consume(reference: session.referenceHash.value), isFalse);
    await expectUnconsumedSession();
  });

  test('rejects a session after it expires', () async {
    expect(
      await consume(now: expiresAt.add(const Duration(seconds: 1))),
      isFalse,
    );
    await expectUnconsumedSession();
  });

  test('rejects a session at its exact expiration time', () async {
    expect(await consume(now: expiresAt), isFalse);
    await expectUnconsumedSession();
  });

  test('rejects a consumed session even when its token remains', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          GitHubConnectionSessionsCompanion(consumedAt: Value(createdAt)),
        );

    expect(
      await consume(now: createdAt.add(const Duration(seconds: 1))),
      isFalse,
    );
    final saved = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(saved.consumedAt?.toUtc(), createdAt);
    expect(saved.encryptedAccessToken, 'encrypted-user-token');
  });

  test('rejects a session whose token has been cleared', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          const GitHubConnectionSessionsCompanion(
            encryptedAccessToken: Value(null),
          ),
        );

    expect(await consume(), isFalse);
    final saved = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(saved.consumedAt, isNull);
    expect(saved.encryptedAccessToken, isNull);
  });

  test(
    'rejects reuse without changing the original consumption time',
    () async {
      expect(await consume(), isTrue);
      expect(
        await consume(now: createdAt.add(const Duration(seconds: 1))),
        isFalse,
      );

      final saved = await db.select(db.gitHubConnectionSessions).getSingle();
      expect(saved.consumedAt?.toUtc(), createdAt);
      expect(saved.encryptedAccessToken, isNull);
    },
  );

  test('only one concurrent caller can consume the session', () async {
    final results = await Future.wait([consume(), consume()]);

    expect(results, unorderedEquals([true, false]));
    final saved = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(saved.consumedAt?.toUtc(), createdAt);
    expect(saved.encryptedAccessToken, isNull);
  });

  test(
    'rolls consumption back when the surrounding transaction fails',
    () async {
      await expectLater(
        db.transaction(() async {
          expect(await consume(), isTrue);
          throw StateError('Connection save failed');
        }),
        throwsStateError,
      );

      await expectUnconsumedSession();
      expect(await consume(), isTrue);
    },
  );

  test('consumes a newly created session using the current time', () async {
    final crypter = SecretCrypter(base64Encode(List<int>.filled(32, 1)));
    final created = await createGitHubConnectionSession(
      db: db,
      crypter: crypter,
      userId: 'user-1',
      teamId: 'team-1',
      githubUserId: 456,
      accessToken: 'new-github-token',
    );

    expect(
      await consumeGitHubConnectionSession(
        db: db,
        reference: created.reference,
        userId: 'user-1',
        teamId: 'team-1',
      ),
      isTrue,
    );
  });

  test('reports database failures without exposing query values', () async {
    await db.customStatement('DROP TABLE github_connection_sessions');

    await expectLater(
      consume(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Failed to consume GitHub connection session',
        ),
      ),
    );
  });
}
