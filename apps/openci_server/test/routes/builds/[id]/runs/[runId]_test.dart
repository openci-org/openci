import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../../routes/builds/[id]/runs/[runId].dart' as route;

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

  group('GET /builds/<id>/runs/<runId>', () {
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
        context.provide<DriftBuildJob>(job);

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
        context.provide<DriftBuildJob>(job);

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
  });

  group('PATCH /builds/<id>/runs/<runId>', () {
    test(
      'responds with 400 Bad Request when body is invalid JSON',
      () async {
        final now = _getNormalizedNow();
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

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456',
          method: HttpMethod.patch,
          body: 'invalid-json',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

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

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456',
          method: HttpMethod.patch,
          body: '{"conclusion": "completed"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

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

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456',
          method: HttpMethod.patch,
          body: '{"status": 123}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

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
        context.provide<DriftBuildJob>(job);

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
        context.provide<DriftBuildJob>(job);

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
  });
}
