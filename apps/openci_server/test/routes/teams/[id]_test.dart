import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:test/test.dart';

import '../../../routes/teams/[id].dart' as route;

class MockAppDatabase extends Mock implements AppDatabase {}

class MockTeamDao extends Mock implements TeamDao {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      DriftTeam(
        id: 'dummy',
        name: 'dummy',
        githubBaseUrl: null,
        githubApiBaseUrl: null,
        installationIds: const [],
        aiEnabled: true,
        runNumber: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('PATCH /teams/<id>', () {
    test(
      'responds with 403 Forbidden when unauthorized (uid is null)',
      () async {
        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: jsonEncode({'name': 'Updated Name'}),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Unauthorized'));
      },
    );

    test(
      'responds with 403 Forbidden when user is not a member of the team',
      () async {
        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: jsonEncode({'name': 'Updated Name'}),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('stranger-user');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Forbidden'));
      },
    );

    test(
      'responds with 500 when membership check database fails',
      () async {
        final mockDb = MockAppDatabase();
        final mockTeamDao = MockTeamDao();

        when(() => mockDb.teamDao).thenReturn(mockTeamDao);
        when(
          () => mockTeamDao.isTeamMember(any(), any()),
        ).thenThrow(Exception('DB membership check error'));

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: jsonEncode({'name': 'Updated Name'}),
        );

        context.provide<AppDatabase>(mockDb);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.internalServerError));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Internal server error'));
      },
    );

    test(
      'responds with 400 Bad Request when body is invalid JSON',
      () async {
        final now = DateTime.now().toUtc();
        final team = DriftTeam(
          id: 'team-123',
          name: 'Original Team',
          installationIds: const [],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, 'user-1');

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: 'not-a-json',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid JSON'));
      },
    );

    test(
      'responds with 400 Bad Request when name is not a string',
      () async {
        final now = DateTime.now().toUtc();
        final team = DriftTeam(
          id: 'team-123',
          name: 'Original Team',
          installationIds: const [],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, 'user-1');

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: jsonEncode({'name': 123}),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('name must be a string'));
      },
    );

    test(
      'responds with 400 Bad Request when name is empty',
      () async {
        final now = DateTime.now().toUtc();
        final team = DriftTeam(
          id: 'team-123',
          name: 'Original Team',
          installationIds: const [],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, 'user-1');

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: jsonEncode({'name': '   '}),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('name cannot be empty'));
      },
    );

    test(
      'responds with 400 Bad Request when githubBaseUrl is not a string or null',
      () async {
        final now = DateTime.now().toUtc();
        final team = DriftTeam(
          id: 'team-123',
          name: 'Original Team',
          installationIds: const [],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, 'user-1');

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: jsonEncode({'githubBaseUrl': 123}),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(
          body['error'],
          contains('githubBaseUrl must be a string or null'),
        );
      },
    );

    test(
      'responds with 400 Bad Request when installationIds is not a list of integers',
      () async {
        final now = DateTime.now().toUtc();
        final team = DriftTeam(
          id: 'team-123',
          name: 'Original Team',
          installationIds: const [],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, 'user-1');

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: jsonEncode({
            'installationIds': ['not-int'],
          }),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(
          body['error'],
          contains('installationIds must be a list of integers'),
        );
      },
    );

    test(
      'responds with 400 Bad Request when aiEnabled is not a boolean',
      () async {
        final now = DateTime.now().toUtc();
        final team = DriftTeam(
          id: 'team-123',
          name: 'Original Team',
          installationIds: const [],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, 'user-1');

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: jsonEncode({'aiEnabled': 'true'}),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('aiEnabled must be a boolean'));
      },
    );

    test(
      'responds with 404 Not Found when team does not exist in DB',
      () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-non-existent',
                userId: 'user-1',
              ),
            );

        final context = TestRequestContext(
          path: '/teams/team-non-existent',
          method: HttpMethod.patch,
          body: jsonEncode({'name': 'New Name'}),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(
          context.context,
          'team-non-existent',
        );

        expect(response.statusCode, equals(HttpStatus.notFound));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Team not found'));
      },
    );

    test(
      'responds with 200 OK and updates team data in database',
      () async {
        final now = DateTime.now().toUtc();
        final teamCreatedAt = DateTime.fromMillisecondsSinceEpoch(
          (now.subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/
                  1000) *
              1000,
          isUtc: true,
        );
        final team = DriftTeam(
          id: 'team-123',
          name: 'Original Team',
          githubBaseUrl: 'https://github.com/original',
          githubApiBaseUrl: 'https://api.github.com/original',
          installationIds: const [111],
          aiEnabled: true,
          runNumber: 5,
          createdAt: teamCreatedAt,
          updatedAt: teamCreatedAt,
        );
        await db.teamDao.createTeamAndMember(team, 'user-1');

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: jsonEncode({
            'name': '   Trimmed Updated Name   ',
            'githubBaseUrl': 'https://github.com/updated',
            'githubApiBaseUrl': null,
            'installationIds': [222, 333],
            'aiEnabled': false,
          }),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final updatedTeam = await (db.select(
          db.teams,
        )..where((t) => t.id.equals('team-123'))).getSingle();

        expect(updatedTeam.name, equals('Trimmed Updated Name'));
        expect(updatedTeam.githubBaseUrl, equals('https://github.com/updated'));
        expect(updatedTeam.githubApiBaseUrl, isNull);
        expect(updatedTeam.installationIds, equals([222, 333]));
        expect(updatedTeam.aiEnabled, isFalse);
        expect(updatedTeam.runNumber, equals(5));
        expect(updatedTeam.createdAt.toUtc(), equals(team.createdAt.toUtc()));
        expect(
          updatedTeam.updatedAt.toUtc().isAfter(team.updatedAt.toUtc()),
          isTrue,
        );
      },
    );

    test(
      'responds with 500 Internal Server Error when database fails on update',
      () async {
        final mockDb = MockAppDatabase();
        final mockTeamDao = MockTeamDao();

        when(() => mockDb.teamDao).thenReturn(mockTeamDao);
        when(
          () => mockTeamDao.isTeamMember(any(), any()),
        ).thenAnswer((_) async => true);

        when(
          () => mockDb.select(mockDb.teams),
        ).thenThrow(Exception('Select failed'));

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.patch,
          body: jsonEncode({'name': 'Failed Team'}),
        );

        context.provide<AppDatabase>(mockDb);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.internalServerError));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Internal server error'));
      },
    );
  });

  group('DELETE /teams/<id>', () {
    test(
      'responds with 403 Forbidden when unauthorized (uid is null)',
      () async {
        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Unauthorized'));
      },
    );

    test(
      'responds with 403 Forbidden when user is not a member of the team',
      () async {
        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('stranger-user');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Forbidden'));
      },
    );

    test(
      'responds with 404 Not Found when team does not exist in DB',
      () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-non-existent',
                userId: 'user-1',
              ),
            );

        final context = TestRequestContext(
          path: '/teams/team-non-existent',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(
          context.context,
          'team-non-existent',
        );

        expect(response.statusCode, equals(HttpStatus.notFound));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Team not found'));
      },
    );

    test(
      'responds with 200 OK and deletes team and member from database',
      () async {
        final now = DateTime.now().toUtc();
        final team = DriftTeam(
          id: 'team-123',
          name: 'Delete Me Team',
          installationIds: const [],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, 'user-1');

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final deletedTeam = await (db.select(
          db.teams,
        )..where((t) => t.id.equals('team-123'))).getSingleOrNull();
        expect(deletedTeam, isNull);

        final members = await (db.select(
          db.teamMembers,
        )..where((m) => m.teamId.equals('team-123'))).get();
        expect(members, isEmpty);
      },
    );

    test(
      'responds with 500 Internal Server Error when database fails on select',
      () async {
        final mockDb = MockAppDatabase();
        final mockTeamDao = MockTeamDao();

        when(() => mockDb.teamDao).thenReturn(mockTeamDao);
        when(
          () => mockTeamDao.isTeamMember(any(), any()),
        ).thenAnswer((_) async => true);

        when(
          () => mockDb.select(mockDb.teams),
        ).thenThrow(Exception('Select failed'));

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(mockDb);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.internalServerError));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Internal server error'));
      },
    );
  });
}
