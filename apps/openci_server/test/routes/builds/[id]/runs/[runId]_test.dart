import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/build_job/build_job_dao.dart';
import 'package:openci_server/build_run/build_run_dao.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../../routes/builds/[id]/runs/[runId].dart' as route;

class MockAppDatabase extends Mock implements AppDatabase {}

class MockBuildJobDao extends Mock implements BuildJobDao {}

class MockBuildRunDao extends Mock implements BuildRunDao {}

class MockTeamDao extends Mock implements TeamDao {}

DateTime _getNormalizedNow() {
  final now = DateTime.now().toUtc();
  return DateTime.utc(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
    now.second,
  );
}

void main() {
  late AppDatabase db;

  setUpAll(() {
    registerFallbackValue(
      DriftBuildRun(
        id: 'dummy',
        buildJobId: 'dummy',
        status: 'dummy',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('GET /builds/<id>/runs/<runId>', () {
    test(
      'responds with 401 Unauthorized (Authentication required) when uid is null',
      () async {
        final context = TestRequestContext(
          path: '/builds/job-123/runs/run-456',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await route.onRequest(
          context.context,
          'job-123',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.unauthorized));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Authentication required'));
      },
    );

    test(
      'responds with 404 Not Found when build job does not exist',
      () async {
        final context = TestRequestContext(
          path: '/builds/non-existent-job/runs/run-456',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'non-existent-job',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.notFound));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Build job not found'));
      },
    );

    test(
      'responds with 403 Forbidden (Forbidden) when build job teamId is null',
      () async {
        final now = _getNormalizedNow();
        final job = DriftBuildJob(
          id: 'job-no-team',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: null,
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-no-team/runs/run-456',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-no-team',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Forbidden'));
      },
    );

    test(
      'responds with 403 Forbidden (Forbidden) when user is not a member of the team',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-abc');

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-xyz',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Forbidden'));
      },
    );

    test(
      'responds with 404 Not Found when build run does not exist',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/non-existent-run',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-xyz',
          'non-existent-run',
        );

        expect(response.statusCode, equals(HttpStatus.notFound));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Build run not found'));
      },
    );

    test(
      'responds with 200 OK and returns build run details when authorized',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final run = DriftBuildRun(
          id: 'run-456',
          buildJobId: 'job-xyz',
          status: 'success',
          conclusion: 'completed',
          createdAt: now.subtract(const Duration(minutes: 5)),
          updatedAt: now.subtract(const Duration(minutes: 4)),
        );

        await db.buildRunDao.insertBuildRun(run);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-xyz',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['id'], equals('run-456'));
        expect(body['buildJobId'], equals('job-xyz'));
        expect(body['status'], equals('success'));
        expect(body['conclusion'], equals('completed'));
        expect(
          body['createdAt'],
          equals(run.createdAt.toUtc().toIso8601String()),
        );
        expect(
          body['updatedAt'],
          equals(run.updatedAt.toUtc().toIso8601String()),
        );
      },
    );

    test(
      'responds with 500 Internal Server Error when database fails',
      () async {
        final mockDb = MockAppDatabase();
        final mockBuildJobDao = MockBuildJobDao();

        when(() => mockDb.buildJobDao).thenReturn(mockBuildJobDao);
        when(
          () => mockBuildJobDao.getBuildJob(any()),
        ).thenThrow(Exception('Database failure'));

        final context = TestRequestContext(
          path: '/builds/job-123/runs/run-456',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(mockDb);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-123',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.internalServerError));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Internal server error'));
      },
    );
  });

  group('PATCH /builds/<id>/runs/<runId>', () {
    test(
      'responds with 401 Unauthorized (Authentication required) when uid is null',
      () async {
        final context = TestRequestContext(
          path: '/builds/job-123/runs/run-456',
          method: HttpMethod.patch,
          body: '{"status": "success"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await route.onRequest(
          context.context,
          'job-123',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.unauthorized));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Authentication required'));
      },
    );

    test(
      'responds with 404 Not Found when build job does not exist',
      () async {
        final context = TestRequestContext(
          path: '/builds/non-existent-job/runs/run-456',
          method: HttpMethod.patch,
          body: '{"status": "success"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'non-existent-job',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.notFound));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Build job not found'));
      },
    );

    test(
      'responds with 403 Forbidden (Forbidden) when build job teamId is null',
      () async {
        final now = _getNormalizedNow();
        final job = DriftBuildJob(
          id: 'job-no-team',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: null,
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-no-team/runs/run-456',
          method: HttpMethod.patch,
          body: '{"status": "success"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-no-team',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Forbidden'));
      },
    );

    test(
      'responds with 403 Forbidden (Forbidden) when user is not a member of the team',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-abc');

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456',
          method: HttpMethod.patch,
          body: '{"status": "success"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-xyz',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Forbidden'));
      },
    );

    test(
      'responds with 400 Bad Request when body is invalid JSON',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456',
          method: HttpMethod.patch,
          body: 'invalid-json',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-xyz',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid JSON'));
      },
    );

    test(
      'responds with 400 Bad Request when status is missing',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456',
          method: HttpMethod.patch,
          body: '{"conclusion": "completed"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-xyz',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('status is required'));
      },
    );

    test(
      'responds with 400 Bad Request when status is not a string (invalid payload structure)',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456',
          method: HttpMethod.patch,
          body: '{"status": 123}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-xyz',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid payload structure'));
      },
    );

    test(
      'responds with 404 Not Found when build run does not exist',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/non-existent-run',
          method: HttpMethod.patch,
          body: '{"status": "success"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-xyz',
          'non-existent-run',
        );

        expect(response.statusCode, equals(HttpStatus.notFound));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Build run not found'));
      },
    );

    test(
      'responds with 200 OK and updates the build run when authorized',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          githubApiBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final run = DriftBuildRun(
          id: 'run-456',
          buildJobId: 'job-xyz',
          status: 'in_progress',
          conclusion: null,
          createdAt: now.subtract(const Duration(minutes: 5)),
          updatedAt: now.subtract(const Duration(minutes: 5)),
        );

        await db.buildRunDao.insertBuildRun(run);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456',
          method: HttpMethod.patch,
          body: '{"status": "success", "conclusion": "completed"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-xyz',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final updatedRun = await db.buildRunDao.getBuildRun(
          'job-xyz',
          'run-456',
        );
        expect(updatedRun, isNotNull);
        expect(updatedRun!.status, equals('success'));
        expect(updatedRun.conclusion, equals('completed'));
        expect(updatedRun.updatedAt.isAfter(run.updatedAt), isTrue);
      },
    );

    test(
      'responds with 500 Internal Server Error when database fails',
      () async {
        final mockDb = MockAppDatabase();
        final mockBuildJobDao = MockBuildJobDao();

        when(() => mockDb.buildJobDao).thenReturn(mockBuildJobDao);
        when(
          () => mockBuildJobDao.getBuildJob(any()),
        ).thenThrow(Exception('Database failure'));

        final context = TestRequestContext(
          path: '/builds/job-123/runs/run-456',
          method: HttpMethod.patch,
          body: '{"status": "success"}',
        );

        context.provide<AppDatabase>(mockDb);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-123',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.internalServerError));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Internal server error'));
      },
    );

    test(
      'responds with 500 Internal Server Error when updateBuildRun returns false',
      () async {
        final mockDb = MockAppDatabase();
        final mockBuildJobDao = MockBuildJobDao();
        final mockBuildRunDao = MockBuildRunDao();
        final mockTeamDao = MockTeamDao();

        final now = _getNormalizedNow();
        final job = DriftBuildJob(
          id: 'job-123',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        final run = DriftBuildRun(
          id: 'run-456',
          buildJobId: 'job-123',
          status: 'in_progress',
          conclusion: null,
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDb.buildJobDao).thenReturn(mockBuildJobDao);
        when(() => mockDb.buildRunDao).thenReturn(mockBuildRunDao);
        when(() => mockDb.teamDao).thenReturn(mockTeamDao);

        when(
          () => mockBuildJobDao.getBuildJob('job-123'),
        ).thenAnswer((_) async => job);
        when(
          () => mockTeamDao.isTeamMember('user-123', 'team-xyz'),
        ).thenAnswer((_) async => true);
        when(
          () => mockBuildRunDao.getBuildRun('job-123', 'run-456'),
        ).thenAnswer((_) async => run);
        when(
          () => mockBuildRunDao.updateBuildRun(any()),
        ).thenAnswer((_) async => false);

        final context = TestRequestContext(
          path: '/builds/job-123/runs/run-456',
          method: HttpMethod.patch,
          body: '{"status": "success"}',
        );

        context.provide<AppDatabase>(mockDb);
        context.provide<String?>('user-123');

        final response = await route.onRequest(
          context.context,
          'job-123',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.internalServerError));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Failed to update build run'));
      },
    );
  });
}
