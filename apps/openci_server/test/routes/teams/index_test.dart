import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:test/test.dart';

import '../../../routes/teams/index.dart' as route;

class MockAppDatabase extends Mock implements AppDatabase {}

class MockTeamDao extends Mock implements TeamDao {}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('GET /teams', () {
    test(
      'responds with 403 Forbidden when unauthorized (uid is null)',
      () async {
        final context = TestRequestContext(
          path: '/teams',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Unauthorized'));
      },
    );

    test(
      'responds with 200 and empty list when user is not in any team',
      () async {
        final context = TestRequestContext(
          path: '/teams',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-no-teams');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as List<dynamic>;
        expect(body, isEmpty);
      },
    );

    test(
      'responds with 200 and teams list when user belongs to teams',
      () async {
        final now = DateTime.now().toUtc();

        final team = DriftTeam(
          id: 'team-abc',
          name: 'My Awesome Team',
          installationIds: [12345],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-1');

        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-abc',
                userId: 'user-2',
              ),
            );

        final context = TestRequestContext(
          path: '/teams',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as List<dynamic>;
        expect(body, hasLength(1));

        final returnedTeam = body.first as Map<String, dynamic>;
        expect(returnedTeam['id'], equals('team-abc'));
        expect(returnedTeam['name'], equals('My Awesome Team'));
        expect(returnedTeam['members'], containsAll(['user-1', 'user-2']));
      },
    );

    test(
      'responds with 500 Internal Server Error when database fails',
      () async {
        final mockDb = MockAppDatabase();
        final mockTeamDao = MockTeamDao();

        when(() => mockDb.teamDao).thenReturn(mockTeamDao);
        when(
          () => mockTeamDao.getTeamsForUser(any()),
        ).thenThrow(Exception('Database error'));

        final context = TestRequestContext(
          path: '/teams',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(mockDb);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.internalServerError));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Internal server error'));
      },
    );
  });
}
