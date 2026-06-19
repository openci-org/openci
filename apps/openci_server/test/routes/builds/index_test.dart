import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/build_job/build_job_dao.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../routes/builds/index.dart' as route;

class MockAppDatabase extends Mock implements AppDatabase {}

class MockBuildJobDao extends Mock implements BuildJobDao {}

class MockTeamDao extends Mock implements TeamDao {}

void main() {
  late AppDatabase db;

  setUpAll(() {
    registerFallbackValue(
      DriftBuildJob(
        id: '',
        status: BuildJobStatus.QUEUED,
        owner: '',
        repo: '',
        workflowName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('POST /builds', () {
    test(
      'responds with 401 Unauthorized (Authentication required) when uid is null',
      () async {
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.unauthorized));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Authentication required'));
      },
    );

    test(
      'responds with 400 Bad Request when body is invalid JSON',
      () async {
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: 'not-a-json',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid JSON'));
      },
    );

    test(
      'responds with 400 Bad Request when body is not a JSON object',
      () async {
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: '"just a string"',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Body must be a JSON object'));
      },
    );

    test(
      'responds with 400 Bad Request when payload structure is invalid (missing required fields)',
      () async {
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: '{"invalid": "field"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid payload structure'));
      },
    );

    test(
      'responds with 403 Forbidden when build job teamId is null',
      () async {
        final payload = {
          'id': 'job-123',
          'status': 'QUEUED',
          'owner': 'owner',
          'repo': 'repo',
          'workflowName': 'workflow',
          'teamId': null,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };

        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: jsonEncode(payload),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Forbidden'));
      },
    );

    test(
      'responds with 403 Forbidden when user is not a member of the team',
      () async {
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await db.teamDao.createTeamAndMember(team, 'user-abc');

        final payload = {
          'id': 'job-123',
          'status': 'QUEUED',
          'owner': 'owner',
          'repo': 'repo',
          'workflowName': 'workflow',
          'teamId': 'team-xyz',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };

        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: jsonEncode(payload),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Forbidden'));
      },
    );

    test(
      'responds with 200 OK and inserts build job when user is a member of the team',
      () async {
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        final payload = {
          'id': 'job-123',
          'status': 'QUEUED',
          'owner': 'owner',
          'repo': 'repo',
          'workflowName': 'workflow',
          'teamId': 'team-xyz',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };

        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: jsonEncode(payload),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['id'], equals('job-123'));

        final inserted = await db.buildJobDao.getBuildJob('job-123');
        expect(inserted, isNotNull);
        expect(inserted!.id, equals('job-123'));
        expect(inserted.teamId, equals('team-xyz'));
      },
    );

    test(
      'responds with 500 Internal Server Error when database fails',
      () async {
        final mockDb = MockAppDatabase();
        final mockBuildJobDao = MockBuildJobDao();

        when(() => mockDb.buildJobDao).thenReturn(mockBuildJobDao);
        when(
          () => mockBuildJobDao.insertBuildJob(any()),
        ).thenThrow(Exception('Database failure'));

        final mockTeamDao = MockTeamDao();
        when(() => mockDb.teamDao).thenReturn(mockTeamDao);
        when(
          () => mockTeamDao.isTeamMember('user-123', 'team-xyz'),
        ).thenAnswer((_) async => true);

        final payload = {
          'id': 'job-123',
          'status': 'QUEUED',
          'owner': 'owner',
          'repo': 'repo',
          'workflowName': 'workflow',
          'teamId': 'team-xyz',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };

        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: jsonEncode(payload),
        );

        context.provide<AppDatabase>(mockDb);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.internalServerError));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Internal server error'));
      },
    );
  });

  group('GET /builds', () {
    test('responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/builds?teamId=team-xyz',
        method: HttpMethod.get,
      );

      context.provide<AppDatabase>(db);
      context.provide<String?>(null);

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'responds with 400 Bad Request when teamId parameter is missing',
      () async {
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Missing teamId parameter'));
      },
    );

    test(
      'responds with 403 Forbidden when user is not a member of the team',
      () async {
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await db.teamDao.createTeamAndMember(team, 'user-abc');

        final context = TestRequestContext(
          path: '/builds?teamId=team-xyz',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test('responds with 200 OK and returns build jobs for the team', () async {
      final team = DriftTeam(
        id: 'team-xyz',
        name: 'Team XYZ',
        githubBaseUrl: null,
        githubApiBaseUrl: null,
        installationIds: const [],
        runNumber: 1,
        aiEnabled: true,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await db.teamDao.createTeamAndMember(team, 'user-123');

      final now = DateTime.now().toUtc();
      final job1 = DriftBuildJob(
        id: 'job-1',
        status: BuildJobStatus.QUEUED,
        owner: 'owner',
        repo: 'repo',
        workflowName: 'workflow',
        teamId: 'team-xyz',
        hasIpa: false,
        createdAt: now,
        updatedAt: now,
      );
      final job2 = DriftBuildJob(
        id: 'job-2',
        status: BuildJobStatus.SUCCESS,
        owner: 'owner',
        repo: 'repo',
        workflowName: 'workflow',
        teamId: 'team-xyz',
        hasIpa: true,
        createdAt: now.add(const Duration(seconds: 1)),
        updatedAt: now.add(const Duration(seconds: 1)),
      );
      final jobOther = DriftBuildJob(
        id: 'job-other',
        status: BuildJobStatus.QUEUED,
        owner: 'owner',
        repo: 'repo',
        workflowName: 'workflow',
        teamId: 'team-other',
        hasIpa: false,
        createdAt: now,
        updatedAt: now,
      );

      await db.buildJobDao.insertBuildJob(job1);
      await db.buildJobDao.insertBuildJob(job2);
      await db.buildJobDao.insertBuildJob(jobOther);

      // Query all jobs for team-xyz
      final contextAll = TestRequestContext(
        path: '/builds?teamId=team-xyz',
        method: HttpMethod.get,
      );
      contextAll.provide<AppDatabase>(db);
      contextAll.provide<String?>('user-123');

      final responseAll = await route.onRequest(contextAll.context);
      expect(responseAll.statusCode, equals(HttpStatus.ok));
      final bodyAll = await responseAll.json() as Map<String, dynamic>;
      expect(bodyAll['success'], isTrue);
      final listAll = bodyAll['buildJobs'] as List<dynamic>;
      expect(listAll, hasLength(2));
      expect(
        listAll[0]['id'],
        equals('job-2'),
      ); // ordered descending by createdAt
      expect(listAll[1]['id'], equals('job-1'));

      // Query jobs with hasIpa=true
      final contextIpa = TestRequestContext(
        path: '/builds?teamId=team-xyz&hasIpa=true',
        method: HttpMethod.get,
      );
      contextIpa.provide<AppDatabase>(db);
      contextIpa.provide<String?>('user-123');

      final responseIpa = await route.onRequest(contextIpa.context);
      expect(responseIpa.statusCode, equals(HttpStatus.ok));
      final bodyIpa = await responseIpa.json() as Map<String, dynamic>;
      final listIpa = bodyIpa['buildJobs'] as List<dynamic>;
      expect(listIpa, hasLength(1));
      expect(listIpa[0]['id'], equals('job-2'));
    });

    test('responds with 400 Bad Request when hasIpa parameter is invalid', () async {
      final team = DriftTeam(
        id: 'team-xyz',
        name: 'Team XYZ',
        githubBaseUrl: null,
        githubApiBaseUrl: null,
        installationIds: const [],
        runNumber: 1,
        aiEnabled: true,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await db.teamDao.createTeamAndMember(team, 'user-123');

      final context = TestRequestContext(
        path: '/builds?teamId=team-xyz&hasIpa=invalid',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('user-123');

      final response = await route.onRequest(context.context);
      expect(response.statusCode, equals(HttpStatus.badRequest));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], contains('Invalid hasIpa parameter'));
    });

    test('responds with 400 Bad Request when limit parameter is invalid', () async {
      final team = DriftTeam(
        id: 'team-xyz',
        name: 'Team XYZ',
        githubBaseUrl: null,
        githubApiBaseUrl: null,
        installationIds: const [],
        runNumber: 1,
        aiEnabled: true,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await db.teamDao.createTeamAndMember(team, 'user-123');

      // Test with non-integer limit
      final contextInvalidString = TestRequestContext(
        path: '/builds?teamId=team-xyz&limit=abc',
        method: HttpMethod.get,
      );
      contextInvalidString.provide<AppDatabase>(db);
      contextInvalidString.provide<String?>('user-123');

      final responseInvalidString = await route.onRequest(contextInvalidString.context);
      expect(responseInvalidString.statusCode, equals(HttpStatus.badRequest));
      final bodyInvalidString = await responseInvalidString.json() as Map<String, dynamic>;
      expect(bodyInvalidString['error'], contains('Invalid limit parameter'));

      // Test with limit < 1
      final contextZero = TestRequestContext(
        path: '/builds?teamId=team-xyz&limit=0',
        method: HttpMethod.get,
      );
      contextZero.provide<AppDatabase>(db);
      contextZero.provide<String?>('user-123');

      final responseZero = await route.onRequest(contextZero.context);
      expect(responseZero.statusCode, equals(HttpStatus.badRequest));

      // Test with limit > 200
      final contextTooLarge = TestRequestContext(
        path: '/builds?teamId=team-xyz&limit=201',
        method: HttpMethod.get,
      );
      contextTooLarge.provide<AppDatabase>(db);
      contextTooLarge.provide<String?>('user-123');

      final responseTooLarge = await route.onRequest(contextTooLarge.context);
      expect(responseTooLarge.statusCode, equals(HttpStatus.badRequest));
    });
  });
}
