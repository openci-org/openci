import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../helpers/database_failure_checks.dart';
import '../../../../../routes/builds/[id]/runs/index.dart' as route;
import '../../../../helpers/github_app_test_key.dart';

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

  group('GitHub Check at build start', () {
    late Directory tempDirectory;
    late Map<String, String> environment;
    late List<http.Request> requests;
    late MockClient client;
    var createStatus = HttpStatus.created;
    var updateStatus = HttpStatus.ok;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('build_run_check_');
      final keyFile = File('${tempDirectory.path}/key.pem');
      await keyFile.writeAsString(testRsaPrivateKey);
      environment = {
        'GITHUB_APP_ID': '123456',
        'GITHUB_PRIVATE_KEY_PATH': keyFile.path,
        'GITHUB_API_BASE_URL': 'https://api.github.com',
      };
      requests = [];
      createStatus = HttpStatus.created;
      updateStatus = HttpStatus.ok;
      client = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/access_tokens')) {
          return http.Response('{"token":"test-token"}', HttpStatus.created);
        }
        if (request.method == 'POST' &&
            request.url.path == '/repos/org/mobile/check-runs') {
          return http.Response('{"id":99999}', createStatus);
        }
        if (request.method == 'PATCH' &&
            request.url.path == '/repos/org/mobile/check-runs/99999') {
          return http.Response('{}', updateStatus);
        }
        fail('Unexpected GitHub request: ${request.method} ${request.url}');
      });
      addTearDown(client.close);
      addTearDown(() => tempDirectory.delete(recursive: true));

      final now = _getNormalizedNow();
      await db.buildJobDao.insertBuildJob(
        DriftBuildJob(
          id: 'job-check',
          status: BuildJobStatus.IN_PROGRESS,
          owner: 'org',
          repo: 'mobile',
          workflowName: 'Flutter CI',
          workflowFileName: 'ci.dart',
          installationId: '98765',
          commitSha: 'abc123',
          runCount: 2,
          latestRunId: 'previous-run',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    Future<Response> startRun({
      String runId = 'run-check',
      bool provideEnvironment = true,
      bool provideClient = true,
    }) async {
      final job = (await db.buildJobDao.getBuildJob('job-check'))!;
      final context = TestRequestContext(
        path: '/builds/job-check/runs',
        method: HttpMethod.post,
        body: jsonEncode({'id': runId}),
      )..provide<AppDatabase>(db);
      context.provide<DriftBuildJob>(job);
      if (provideEnvironment) {
        context.provide<Map<String, String>>(environment);
      }
      if (provideClient) context.provide<http.Client>(client);
      return route.onRequest(context.context, job.id);
    }

    List<http.Request> checkRequests() => requests
        .where((request) => request.url.path.contains('/check-runs'))
        .toList();

    for (final checkRunId in [null, '']) {
      test('creates and saves a Check when the ID is $checkRunId', () async {
        await db
            .update(db.buildJobs)
            .write(
              BuildJobsCompanion(checkRunId: Value(checkRunId)),
            );

        final response = await startRun();

        expect(response.statusCode, HttpStatus.ok);
        final request = checkRequests().single;
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), containsPair('head_sha', 'abc123'));
        expect(jsonDecode(request.body), containsPair('name', 'Flutter CI'));
        expect(
          jsonDecode(request.body),
          containsPair('external_id', 'job-check'),
        );
        final stored = (await db.buildJobDao.getBuildJob('job-check'))!;
        expect(stored.checkRunId, '99999');
        expect(stored.runCount, 3);
        expect(stored.latestRunId, 'run-check');
        expect(stored.status, BuildJobStatus.IN_PROGRESS);
        expect(
          (await db.buildRunDao.getBuildRun('job-check', 'run-check'))!.status,
          'in_progress',
        );
      });
    }

    test('reuses the saved Check on a subsequent run', () async {
      expect((await startRun()).statusCode, HttpStatus.ok);
      expect((await startRun(runId: 'rerun')).statusCode, HttpStatus.ok);

      final calls = checkRequests();
      expect(calls.map((request) => request.method), ['POST', 'PATCH']);
      expect(calls.last.url.path, '/repos/org/mobile/check-runs/99999');
      final body = jsonDecode(calls.last.body) as Map<String, dynamic>;
      expect(DateTime.parse(body.remove('started_at') as String).isUtc, isTrue);
      expect(body, {'status': 'in_progress'});
      final stored = (await db.buildJobDao.getBuildJob('job-check'))!;
      expect(stored.checkRunId, '99999');
      expect(stored.runCount, 4);
      expect(stored.latestRunId, 'rerun');
    });

    test('does not create another Check for a duplicate run ID', () async {
      expect((await startRun()).statusCode, HttpStatus.ok);
      expect((await startRun()).statusCode, HttpStatus.conflict);
      expect(checkRequests(), hasLength(1));
    });

    test('keeps the build run when Check creation fails', () async {
      createStatus = HttpStatus.forbidden;

      expect((await startRun()).statusCode, HttpStatus.ok);
      expect(checkRequests().single.method, 'POST');
      final stored = (await db.buildJobDao.getBuildJob('job-check'))!;
      expect(stored.checkRunId, isNull);
      expect(stored.runCount, 3);
      expect(
        await db.buildRunDao.getBuildRun('job-check', 'run-check'),
        isNotNull,
      );
    });

    test('preserves an existing Check if its update fails', () async {
      await db
          .update(db.buildJobs)
          .write(
            const BuildJobsCompanion(
              checkRunId: Value('99999'),
              commitSha: Value(null),
            ),
          );
      updateStatus = HttpStatus.internalServerError;

      expect((await startRun()).statusCode, HttpStatus.ok);
      expect(checkRequests().single.method, 'PATCH');
      expect(
        (await db.buildJobDao.getBuildJob('job-check'))!.checkRunId,
        '99999',
      );
    });

    for (final installationId in [null, '', '12345678']) {
      test(
        'skips GitHub for an absent or dummy installation: $installationId',
        () async {
          await db
              .update(db.buildJobs)
              .write(
                BuildJobsCompanion(installationId: Value(installationId)),
              );

          expect((await startRun()).statusCode, HttpStatus.ok);
          expect(requests, isEmpty);
          expect(
            (await db.buildJobDao.getBuildJob('job-check'))!.checkRunId,
            isNull,
          );
        },
      );
    }

    for (final commitSha in [null, '']) {
      test('skips Check creation when commit SHA is $commitSha', () async {
        await db
            .update(db.buildJobs)
            .write(
              BuildJobsCompanion(commitSha: Value(commitSha)),
            );

        final response = await startRun(
          provideEnvironment: false,
          provideClient: false,
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(requests, isEmpty);
        expect(
          (await db.buildJobDao.getBuildJob('job-check'))!.checkRunId,
          isNull,
        );
      });
    }
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

  testDatabaseFailures([
    DatabaseFailureEndpoint(
      '/builds/job-1/runs',
      HttpMethod.get,
      (c) => route.onRequest(c, 'job-1'),
    ),
    DatabaseFailureEndpoint(
      '/builds/job-1/runs',
      HttpMethod.post,
      (c) => route.onRequest(c, 'job-1'),
      body: '{"id":"run-1"}',
    ),
  ]);
}
