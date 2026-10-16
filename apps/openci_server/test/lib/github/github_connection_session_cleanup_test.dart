import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_session_cleanup.dart';
import 'package:test/test.dart';

class _DeleteInterceptor extends QueryInterceptor {
  int calls = 0;
  Completer<void>? blocked;
  Object? failure;

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    calls++;
    await blocked?.future;
    if (failure != null) throw failure!;
    return executor.runDelete(statement, args);
  }
}

class _MockStdout extends Mock implements Stdout {}

void main() {
  late AppDatabase db;
  late _DeleteInterceptor deletes;
  late GitHubConnectionSessionCleanup cleanup;

  setUp(() async {
    deletes = _DeleteInterceptor();
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ).interceptWith(deletes),
    );
    cleanup = GitHubConnectionSessionCleanup(db);
    final now = DateTime.now().toUtc();
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [],
        aiEnabled: false,
        runNumber: 1,
        createdAt: now,
        updatedAt: now,
      ),
      'user-1',
    );
    final expired = GitHubConnectionSessionsCompanion.insert(
      id: 'expired-session',
      userId: 'user-1',
      teamId: 'team-1',
      githubUserId: 123,
      referenceHash: 'expired-reference-hash',
      encryptedAccessToken: const Value('encrypted-user-token'),
      createdAt: now.subtract(const Duration(minutes: 20)),
      expiresAt: now.subtract(const Duration(minutes: 10)),
    );
    await db.into(db.gitHubConnectionSessions).insert(expired);
    await db
        .into(db.gitHubConnectionSessions)
        .insert(
          expired.copyWith(
            id: const Value('active-session'),
            referenceHash: const Value('active-reference-hash'),
            expiresAt: Value(now.add(const Duration(hours: 1))),
          ),
        );
  });

  tearDown(() async {
    await cleanup.stop();
    await db.close();
  });

  test('removes expired sessions immediately on start', () async {
    fakeAsync((time) {
      cleanup.start();
      time.flushMicrotasks();
      expect(deletes.calls, 1);
    });

    final remaining = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(remaining.id, 'active-session');
    expect(remaining.encryptedAccessToken, 'encrypted-user-token');
  });

  test('runs again every minute without incoming requests', () {
    fakeAsync((time) {
      cleanup.start();
      time.flushMicrotasks();

      time.elapse(const Duration(seconds: 59));
      expect(deletes.calls, 1);
      time.elapse(const Duration(seconds: 1));
      expect(deletes.calls, 2);
      time.elapse(const Duration(minutes: 1));
      expect(deletes.calls, 3);
    });
  });

  test('starting twice does not create another cleanup schedule', () {
    fakeAsync((time) {
      cleanup.start();
      time.flushMicrotasks();
      cleanup.start();
      time.flushMicrotasks();
      expect(deletes.calls, 1);

      time.elapse(const Duration(minutes: 1));
      expect(deletes.calls, 2);
    });
  });

  test('skips ticks while a previous deletion is still running', () {
    fakeAsync((time) {
      deletes.blocked = Completer<void>();
      cleanup.start();
      time.flushMicrotasks();
      expect(deletes.calls, 1);

      time.elapse(const Duration(minutes: 3));
      expect(deletes.calls, 1);

      deletes.blocked!.complete();
      time.flushMicrotasks();
      time.elapse(const Duration(minutes: 1));
      expect(deletes.calls, 2);
    });
  });

  test(
    'retries after a database failure without logging private details',
    () async {
      final errorOutput = _MockStdout();
      IOOverrides.runZoned(
        () => fakeAsync((time) {
          deletes.failure = StateError('private database detail');
          cleanup.start();
          time.flushMicrotasks();
          expect(deletes.calls, 1);

          deletes.failure = null;
          time.elapse(const Duration(minutes: 1));
          expect(deletes.calls, 2);
        }),
        stderr: () => errorOutput,
      );

      verify(
        () => errorOutput.writeln(
          'Failed to clean up expired GitHub connection sessions',
        ),
      ).called(1);
      verifyNoMoreInteractions(errorOutput);
      final remaining = await db
          .select(db.gitHubConnectionSessions)
          .getSingle();
      expect(remaining.id, 'active-session');
    },
  );

  test('stop cancels subsequent cleanup runs', () {
    fakeAsync((time) {
      cleanup.start();
      time.flushMicrotasks();
      cleanup.stop();
      time.flushMicrotasks();

      time.elapse(const Duration(minutes: 3));
      expect(deletes.calls, 1);
    });
  });

  test('stop waits for the current deletion to finish', () {
    fakeAsync((time) {
      deletes.blocked = Completer<void>();
      cleanup.start();
      time.flushMicrotasks();
      var stopped = false;
      cleanup.stop().then((_) => stopped = true);
      time.flushMicrotasks();
      expect(stopped, isFalse);

      time.elapse(const Duration(minutes: 3));
      expect(deletes.calls, 1);
      deletes.blocked!.complete();
      time.flushMicrotasks();
      expect(stopped, isTrue);
    });
  });
}
