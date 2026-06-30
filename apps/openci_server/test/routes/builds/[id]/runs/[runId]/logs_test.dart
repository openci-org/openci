import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../../../routes/builds/[id]/runs/[runId]/logs.dart' as route;

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
      'responds with 200 OK and returns log text when authorized',
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
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(
          context.context,
          'job-xyz',
          'run-456',
        );

        expect(response.statusCode, equals(HttpStatus.ok));
        expect(response.headers['content-type'], contains('text/plain'));
        expect(response.headers['content-type'], contains('charset=utf-8'));
        expect(response.headers['x-total-lines'], equals('2'));
        expect(response.headers['x-has-more'], equals('false'));

        final bodyText = await response.body();
        expect(bodyText, equals('line 1\nline 2\n'));
      },
    );

    test(
      'responds with 200 OK and returns paginated logs with headers when limit and offset are provided',
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

        await db.buildJobDao.insertBuildJobLog(
          'run-456',
          'line 1\nline 2\nline 3\n',
        );

        // Test with limit=2, offset=0
        final context1 = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456/logs?limit=2&offset=0',
          method: HttpMethod.get,
        );
        context1.provide<AppDatabase>(db);
        context1.provide<String?>('user-123');
        context1.provide<DriftBuildJob>(job);

        final response1 = await route.onRequest(
          context1.context,
          'job-xyz',
          'run-456',
        );

        expect(response1.statusCode, equals(HttpStatus.ok));
        expect(response1.headers['x-total-lines'], equals('3'));
        expect(response1.headers['x-has-more'], equals('true'));
        expect(await response1.body(), equals('line 1\nline 2\n'));

        // Test with limit=2, offset=2
        final context2 = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456/logs?limit=2&offset=2',
          method: HttpMethod.get,
        );
        context2.provide<AppDatabase>(db);
        context2.provide<String?>('user-123');
        context2.provide<DriftBuildJob>(job);

        final response2 = await route.onRequest(
          context2.context,
          'job-xyz',
          'run-456',
        );

        expect(response2.statusCode, equals(HttpStatus.ok));
        expect(response2.headers['x-total-lines'], equals('3'));
        expect(response2.headers['x-has-more'], equals('false'));
        expect(await response2.body(), equals('line 3\n'));
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
      'responds with 405 Method Not Allowed when HTTP method is not GET or POST',
      () async {
        final context = TestRequestContext(
          path: '/builds/job-123/runs/run-456/logs',
          method: HttpMethod.delete,
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

  group('POST /builds/<id>/runs/<runId>/logs', () {
    test(
      'responds with 404 Not Found when build run does not exist',
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
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );

        await db.buildJobDao.insertBuildJob(job);

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/non-existent-run/logs',
          method: HttpMethod.post,
          body: '{"logs": [{"message": "hello"}]}',
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
      'responds with 400 Bad Request when body is invalid JSON',
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

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456/logs',
          method: HttpMethod.post,
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
      'responds with 200 OK and inserts log text to database when authorized',
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

        final context = TestRequestContext(
          path: '/builds/job-xyz/runs/run-456/logs',
          method: HttpMethod.post,
          body: '{"logs": [{"message": "hello"}, {"message": "world"}]}',
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

        final logs = await db.buildJobDao.getBuildJobLogs('run-456');
        expect(
          logs.map((l) => l.logContent).join(''),
          equals('hello\nworld\n'),
        );
      },
    );
  });
}
