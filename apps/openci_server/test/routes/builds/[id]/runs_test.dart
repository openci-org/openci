import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/builds/[id]/runs/index.dart' as route;

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

  group('POST /builds/<id>/runs', () {
    test(
      'responds with 400 Bad Request when body is invalid JSON',
      () async {
        final now = _getNormalizedNow();
        final job = DriftBuildJob(
          id: 'job-123',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        final context = TestRequestContext(
          path: '/builds/job-123/runs',
          method: HttpMethod.post,
          body: 'not-a-json',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid JSON format'));
      },
    );

    test(
      'responds with 400 Bad Request when run id is missing',
      () async {
        final now = _getNormalizedNow();
        final job = DriftBuildJob(
          id: 'job-123',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        final context = TestRequestContext(
          path: '/builds/job-123/runs',
          method: HttpMethod.post,
          body: '{}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('id is required'));
      },
    );

    test(
      'responds with 400 Bad Request when run id is empty',
      () async {
        final now = _getNormalizedNow();
        final job = DriftBuildJob(
          id: 'job-123',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        final context = TestRequestContext(
          path: '/builds/job-123/runs',
          method: HttpMethod.post,
          body: '{"id": ""}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('id is required'));
      },
    );

    test(
      'responds with 200 OK, inserts a BuildRun, and updates build job runCount/latestRunId when authorized',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
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
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          runCount: 2,
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs',
          method: HttpMethod.post,
          body: '{"id": "run-456"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-xyz');

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final driftRun = await db.buildRunDao.getBuildRun('job-xyz', 'run-456');
        expect(driftRun, isNotNull);
        expect(driftRun!.status, equals('in_progress'));

        final updatedJob = await db.buildJobDao.getBuildJob('job-xyz');
        expect(updatedJob, isNotNull);
        expect(updatedJob!.latestRunId, equals('run-456'));
        expect(updatedJob.runCount, equals(3));
      },
    );

    test(
      'responds with 409 Conflict when runId already exists (unique constraint violation)',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
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
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        // First run creation
        final context1 = TestRequestContext(
          path: '/builds/job-xyz/runs',
          method: HttpMethod.post,
          body: '{"id": "run-duplicate"}',
        );
        context1.provide<AppDatabase>(db);
        context1.provide<String?>('user-123');
        context1.provide<DriftBuildJob>(job);

        final response1 = await route.onRequest(context1.context, 'job-xyz');
        expect(response1.statusCode, equals(HttpStatus.ok));

        // Second run creation with the same runId
        final context2 = TestRequestContext(
          path: '/builds/job-xyz/runs',
          method: HttpMethod.post,
          body: '{"id": "run-duplicate"}',
        );
        context2.provide<AppDatabase>(db);
        context2.provide<String?>('user-123');
        context2.provide<DriftBuildJob>(job);

        final response2 = await route.onRequest(context2.context, 'job-xyz');
        expect(response2.statusCode, equals(HttpStatus.conflict));

        final body2 = await response2.json() as Map<String, dynamic>;
        expect(body2['success'], isFalse);
        expect(body2['error'], equals('Run ID already exists'));
      },
    );

    test(
      'responds with 400 Bad Request when run id is not a string (invalid payload structure)',
      () async {
        final now = _getNormalizedNow();
        final job = DriftBuildJob(
          id: 'job-123',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        final context = TestRequestContext(
          path: '/builds/job-123/runs',
          method: HttpMethod.post,
          body: '{"id": 123}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid payload structure'));
      },
    );
  });

  group('GET /builds/<id>/runs', () {
    test(
      'responds with 200 OK and returns a list of build runs when authorized',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
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
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final run1 = DriftBuildRun(
          id: 'run-1',
          buildJobId: 'job-xyz',
          status: 'success',
          conclusion: 'completed',
          createdAt: now.subtract(const Duration(minutes: 5)),
          updatedAt: now.subtract(const Duration(minutes: 4)),
        );

        final run2 = DriftBuildRun(
          id: 'run-2',
          buildJobId: 'job-xyz',
          status: 'in_progress',
          conclusion: null,
          createdAt: now,
          updatedAt: now,
        );

        await db.buildRunDao.insertBuildRun(run1);
        await db.buildRunDao.insertBuildRun(run2);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-xyz');

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as List<dynamic>;
        expect(body, hasLength(2));

        final r1 = body[0] as Map<String, dynamic>;
        expect(r1['id'], equals('run-1'));
        expect(r1['buildJobId'], equals('job-xyz'));
        expect(r1['status'], equals('success'));
        expect(r1['conclusion'], equals('completed'));
        expect(
          r1['createdAt'],
          equals(run1.createdAt.toUtc().toIso8601String()),
        );
        expect(
          r1['updatedAt'],
          equals(run1.updatedAt.toUtc().toIso8601String()),
        );

        final r2 = body[1] as Map<String, dynamic>;
        expect(r2['id'], equals('run-2'));
        expect(r2['buildJobId'], equals('job-xyz'));
        expect(r2['status'], equals('in_progress'));
        expect(r2['conclusion'], isNull);
        expect(
          r2['createdAt'],
          equals(run2.createdAt.toUtc().toIso8601String()),
        );
        expect(
          r2['updatedAt'],
          equals(run2.updatedAt.toUtc().toIso8601String()),
        );
      },
    );
  });
}
