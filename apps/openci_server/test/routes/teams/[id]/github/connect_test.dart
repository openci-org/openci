import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../../../../routes/teams/[id]/github/connect.dart' as route;

class _MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  test(
    'rejects unauthenticated callers even with a user ID in the body',
    () async {
      final context = TestRequestContext(
        path: '/teams/team-1/github/connect',
        method: HttpMethod.post,
        body: jsonEncode({'userId': 'user-1'}),
      );
      context.provide<String?>(null);

      final response = await route.onRequest(context.context, 'team-1');

      expect(response.statusCode, HttpStatus.unauthorized);
      expect(await response.json(), {
        'success': false,
        'error': 'Authentication required',
      });
    },
  );

  group('team membership', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());

      await db.teamDao.createTeamAndMember(
        DriftTeam(
          id: 'team-1',
          name: 'team-1',
          installationIds: const [123],
          aiEnabled: true,
          runNumber: 1,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        'user-1',
      );

      await db.teamDao.createTeamAndMember(
        DriftTeam(
          id: 'team-2',
          name: 'team-2',
          installationIds: const [123],
          aiEnabled: true,
          runNumber: 1,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        'user-2',
      );
    });

    tearDown(() => db.close());

    Future<Response> post({
      String? uid = 'user-1',
      String teamId = 'team-1',
      String? body,
    }) async {
      final context = TestRequestContext(
        path: '/teams/$teamId/github/connect',
        method: HttpMethod.post,
        body: body,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(uid);
      return route.onRequest(context.context, teamId);
    }

    test(
      'rejects a non-member even with a member user ID in the body',
      () async {
        final response = await post(
          uid: 'outsider',
          teamId: 'team-1',
          body: jsonEncode({'userId': 'user-1', 'teamId': 'team-1'}),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
      },
    );

    test(
      'rejects access to another team even with own team ID in the body',
      () async {
        final response = await post(
          uid: 'user-1',
          teamId: 'team-2',
          body: jsonEncode({'userId': 'user-1', 'teamId': 'team-1'}),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
      },
    );

    test(
      'rejects a missing team even with an existing team ID in the body',
      () async {
        final response = await post(
          uid: 'user-1',
          teamId: 'missing-team',
          body: jsonEncode({'userId': 'user-1', 'teamId': 'team-1'}),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
      },
    );

    test(
      'authenticated team members reach the unimplemented connection step',
      () async {
        final response = await post();

        expect(response.statusCode, HttpStatus.notImplemented);
        expect(await response.json(), {
          'success': false,
          'error': 'GitHub connection is not implemented yet',
        });
      },
    );
  });

  test('returns 500 without leaking database error details', () async {
    final unavailableDb = _MockAppDatabase();
    when(() => unavailableDb.teamDao).thenThrow(
      StateError('private database connection detail'),
    );

    final context = TestRequestContext(
      path: '/teams/team-1/github/connect',
      method: HttpMethod.post,
    );
    context.provide<AppDatabase>(unavailableDb);
    context.provide<String?>('user-1');

    final response = await route.onRequest(context.context, 'team-1');

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(await response.json(), {
      'success': false,
      'error': 'Internal server error',
    });
    verify(() => unavailableDb.teamDao).called(1);
  });

  test('rejects PUT before accessing the database', () async {
    final unusedDb = _MockAppDatabase();
    final context = TestRequestContext(
      path: '/teams/team-1/github/connect',
      method: HttpMethod.put,
    );
    context.provide<AppDatabase>(unusedDb);

    final response = await route.onRequest(context.context, 'team-1');

    expect(response.statusCode, HttpStatus.methodNotAllowed);
    verifyZeroInteractions(unusedDb);
  });
}
