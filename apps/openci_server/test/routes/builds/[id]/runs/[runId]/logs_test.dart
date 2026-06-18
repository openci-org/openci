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

import '../../../../../../routes/builds/[id]/runs/[runId]/logs.dart' as route;

class MockAppDatabase extends Mock implements AppDatabase {}

class MockBuildJobDao extends Mock implements BuildJobDao {}

class MockTeamDao extends Mock implements TeamDao {}

class MockBuildRunDao extends Mock implements BuildRunDao {}

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

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('GET /builds/<id>/runs/<runId>/logs', () {
    test(
      'responds with 401 Unauthorized (Authentication required) when uid is null',
      () async {
        final context = TestRequestContext(
          path: '/builds/job-123/runs/run-456/logs',
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
          path: '/builds/non-existent-job/runs/run-456/logs',
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
          path: '/builds/job-no-team/runs/run-456/logs',
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
          path: '/builds/job-xyz/runs/run-456/logs',
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
      'responds with 200 OK and returns log text when authorized',
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
          createdAt: now,
          updatedAt: now,
        );
        await db.buildRunDao.insertBuildRun(run);

        await db.buildJobDao.insertBuildJobLog('run-456', 'line 1\n');
        await db.buildJobDao.insertBuildJobLog('run-456', 'line 2\n');

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456/logs',
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
        expect(response.headers['content-type'], contains('text/plain'));
        expect(response.headers['content-type'], contains('charset=utf-8'));

        final bodyText = await response.body();
        expect(bodyText, equals('line 1\nline 2\n'));
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
          path: '/builds/job-xyz/runs/non-existent-run/logs',
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
      'responds with 500 Internal Server Error when database fails',
      () async {
        final mockDb = MockAppDatabase();
        final mockBuildJobDao = MockBuildJobDao();
        final mockBuildRunDao = MockBuildRunDao();

        when(() => mockDb.buildJobDao).thenReturn(mockBuildJobDao);
        when(() => mockDb.buildRunDao).thenReturn(mockBuildRunDao);
        when(
          () => mockBuildJobDao.getBuildJob(any()),
        ).thenThrow(Exception('Database failure'));

        final context = TestRequestContext(
          path: '/builds/job-123/runs/run-456/logs',
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

    test(
      'responds with 405 Method Not Allowed when HTTP method is not GET',
      () async {
        final context = TestRequestContext(
          path: '/builds/job-123/runs/run-456/logs',
          method: HttpMethod.post,
        );

        final response = await route.onRequest(
          context.context,
          'job-123',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      },
    );
  });
}
