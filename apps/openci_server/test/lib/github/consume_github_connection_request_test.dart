import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/consume_github_connection_request.dart';
import 'package:openci_server/github/create_github_connection_request.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  const state = 'github-connection-state';
  final createdAt = DateTime.utc(2026, 10, 16, 12);
  final expiresAt = createdAt.add(const Duration(minutes: 10));
  final request = DriftGitHubConnectionRequest(
    id: 'request-1',
    userId: 'user-1',
    teamId: 'team-1',
    stateHash: sha256.convert(utf8.encode(state)).toString(),
    codeVerifier: 'code-verifier',
    createdAt: createdAt,
    expiresAt: expiresAt,
  );

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await db
        .into(db.teams)
        .insert(
          DriftTeam(
            id: 'team-1',
            name: 'OpenCI',
            installationIds: const [],
            aiEnabled: false,
            runNumber: 1,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    await db.into(db.gitHubConnectionRequests).insert(request);
  });

  tearDown(() => db.close());

  test('returns and deletes only the matching unexpired request', () async {
    final otherRequest = request.copyWith(
      id: 'request-2',
      userId: 'user-2',
      stateHash: sha256.convert(utf8.encode('other-state')).toString(),
    );
    await db.into(db.gitHubConnectionRequests).insert(otherRequest);

    final consumed = await consumeGitHubConnectionRequest(
      db: db,
      state: state,
      now: expiresAt.subtract(const Duration(seconds: 1)),
    );

    expect(consumed, isNotNull);
    expect(consumed!.id, request.id);
    expect(consumed.userId, request.userId);
    expect(consumed.teamId, request.teamId);
    expect(consumed.codeVerifier, request.codeVerifier);
    expect(consumed.createdAt.toUtc(), createdAt);
    expect(consumed.expiresAt.toUtc(), expiresAt);
    final remaining = await db.select(db.gitHubConnectionRequests).get();
    expect(remaining.map((request) => request.id), ['request-2']);
  });

  test(
    'returns null for an unknown state without consuming a request',
    () async {
      final consumed = await consumeGitHubConnectionRequest(
        db: db,
        state: 'unknown-state',
        now: createdAt,
      );

      expect(consumed, isNull);
      expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    },
  );

  test('does not accept the stored hash as the original state', () async {
    final consumed = await consumeGitHubConnectionRequest(
      db: db,
      state: request.stateHash,
      now: createdAt,
    );

    expect(consumed, isNull);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
  });

  test('returns null after the request expires', () async {
    final consumed = await consumeGitHubConnectionRequest(
      db: db,
      state: state,
      now: expiresAt.add(const Duration(seconds: 1)),
    );

    expect(consumed, isNull);
  });

  test('returns null at the exact expiration time', () async {
    final consumed = await consumeGitHubConnectionRequest(
      db: db,
      state: state,
      now: expiresAt,
    );

    expect(consumed, isNull);
  });

  test('returns null when the same state is consumed again', () async {
    final first = await consumeGitHubConnectionRequest(
      db: db,
      state: state,
      now: createdAt,
    );
    final second = await consumeGitHubConnectionRequest(
      db: db,
      state: state,
      now: createdAt,
    );

    expect(first?.id, request.id);
    expect(second, isNull);
  });

  test('only one concurrent caller receives the request', () async {
    final results = await Future.wait([
      consumeGitHubConnectionRequest(db: db, state: state, now: createdAt),
      consumeGitHubConnectionRequest(db: db, state: state, now: createdAt),
    ]);

    expect(results.whereType<DriftGitHubConnectionRequest>(), hasLength(1));
    expect(
      results.whereType<DriftGitHubConnectionRequest>().single.id,
      request.id,
    );
    expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
  });

  test('consumes a newly created request using the current time', () async {
    final created = await createGitHubConnectionRequest(
      db: db,
      userId: 'user-1',
      teamId: 'team-1',
    );

    final consumed = await consumeGitHubConnectionRequest(
      db: db,
      state: created.state,
    );

    expect(consumed?.id, created.id);
  });
}
