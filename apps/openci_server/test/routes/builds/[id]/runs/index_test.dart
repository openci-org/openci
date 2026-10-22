import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../helpers/database_failure_checks.dart';
import '../../../../../routes/builds/[id]/_middleware.dart' as build;
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
  late Map<String, String> environment;
  late List<http.Request> requests;
  late MockClient client;
  var repositoryInstallationId = 98765;
  var lookupStatus = HttpStatus.ok;
  var tokenStatus = HttpStatus.created;
  var token = 'test-token';
  var createStatus = HttpStatus.created;
  var updateStatus = HttpStatus.ok;
  Completer<http.Response>? pendingCheck;
  Future<void> Function()? onRepositoryLookup;

  final connection = DriftGitHubConnection(
    id: 'connection-1',
    teamId: 'team-xyz',
    githubApiBaseUrl: 'https://api.github.com',
    githubAppId: 123456,
    installationId: 98765,
    accountId: 42,
    accountType: GitHubAccountType.organization,
    accountLogin: 'org',
    verifiedByUserId: 'user-123',
    verifiedByGitHubUserId: 100,
    verifiedAt: DateTime.utc(2026),
    status: GitHubConnectionStatus.active,
  );

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    final directory = await Directory.systemTemp.createTemp('build_run_check_');
    final keyFile = File('${directory.path}/key.pem');
    await keyFile.writeAsString(testRsaPrivateKey);
    addTearDown(() => directory.delete(recursive: true));
    environment = {
      'GITHUB_APP_ID': '123456',
      'GITHUB_PRIVATE_KEY_PATH': keyFile.path,
      'GITHUB_API_BASE_URL': 'https://api.github.com',
    };
    requests = [];
    repositoryInstallationId = 98765;
    lookupStatus = HttpStatus.ok;
    tokenStatus = HttpStatus.created;
    token = 'test-token';
    createStatus = HttpStatus.created;
    updateStatus = HttpStatus.ok;
    pendingCheck = null;
    onRepositoryLookup = null;
    client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/installation')) {
        await onRepositoryLookup?.call();
        return http.Response(
          jsonEncode({'id': repositoryInstallationId}),
          lookupStatus,
        );
      }
      if (request.url.path.endsWith('/access_tokens')) {
        return http.Response(jsonEncode({'token': token}), tokenStatus);
      }
      if (request.method == 'POST' &&
          request.url.path.endsWith('/check-runs')) {
        if (pendingCheck != null) return pendingCheck!.future;
        return http.Response('{"id":99999}', createStatus);
      }
      if (request.method == 'PATCH' &&
          request.url.path.endsWith('/check-runs/99999')) {
        return http.Response('{}', updateStatus);
      }
      return http.Response('Unexpected GitHub request', 500);
    });
    addTearDown(client.close);
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
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');
        await db.into(db.gitHubConnections).insert(connection);

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          runCount: 2,
          installationId: '98765',
          commitSha: 'abc123',
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
        context.provide<Map<String, String>>(environment);
        context.provide<http.Client>(client);

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
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');
        await db.into(db.gitHubConnections).insert(connection);

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          installationId: '98765',
          commitSha: 'abc123',
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
        context1.provide<Map<String, String>>(environment);
        context1.provide<http.Client>(client);

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
        context2.provide<Map<String, String>>(environment);
        context2.provide<http.Client>(client);

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
    setUp(() async {
      final now = _getNormalizedNow();
      await db.teamDao.createTeamAndMember(
        DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        ),
        'user-123',
      );
      await db.into(db.gitHubConnections).insert(connection);
      await db.buildJobDao.insertBuildJob(
        DriftBuildJob(
          id: 'job-check',
          status: BuildJobStatus.IN_PROGRESS,
          owner: 'org',
          repo: 'mobile',
          workflowName: 'Flutter CI',
          workflowFileName: 'ci.dart',
          teamId: 'team-xyz',
          installationId: '98765',
          githubBaseUrl: 'https://untrusted.example',
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
      String? uid,
      String? bearerToken = 'test-internal-key',
      Map<String, Object?> admission = const {},
    }) async {
      final handler =
          ((RequestContext context) => route.onRequest(context, 'job-check'))
              .use(build.middleware)
              .use(provider<AppDatabase>((_) => db))
              .use(provider<String?>((_) => uid))
              .use(provider<Map<String, String>>((_) => environment))
              .use(provider<http.Client>((_) => client))
              .use(
                provider<InternalApiKeyValidator>(
                  (_) => const InternalApiKeyValidator(
                    environment: {'INTERNAL_API_KEY': 'test-internal-key'},
                  ),
                ),
              );
      final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
      final requestClient = http.Client();
      try {
        final response = await requestClient.post(
          Uri(
            scheme: 'http',
            host: server.address.address,
            port: server.port,
            path: '/builds/job-check/runs',
          ),
          body: jsonEncode({'id': runId, ...admission}),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            if (bearerToken != null)
              HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
          },
        );
        return Response(statusCode: response.statusCode, body: response.body);
      } finally {
        requestClient.close();
        await server.close(force: true);
      }
    }

    List<http.Request> checkRequests() => requests
        .where((request) => request.url.path.contains('/check-runs'))
        .toList();

    Future<void> expectRunNotStarted() async {
      expect(await db.select(db.buildRuns).get(), isEmpty);
      final stored = (await db.buildJobDao.getBuildJob('job-check'))!;
      expect(stored.runCount, 2);
      expect(stored.latestRunId, 'previous-run');
    }

    Future<void> expectConnectionRejected(
      DriftGitHubConnection rejectedConnection,
    ) async {
      await db.update(db.gitHubConnections).replace(rejectedConnection);

      final response = await startRun();

      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.json(), {'success': false, 'error': 'Forbidden'});
      expect(requests, isEmpty);
      await expectRunNotStarted();
    }

    group('Cloud run admission', () {
      setUp(() {
        environment['SERVER_ACCESS_MODE'] = 'cloud';
        environment['BILLING_ENABLED'] = 'false';
      });

      for (final admission in <Map<String, Object?>>[
        {},
        {'billingAdmissionId': 'admission-1'},
        {'billingAdmissionId': 123, 'workerHost': 'worker-1'},
      ]) {
        test(
          'billing requires a complete admission identity: $admission',
          () async {
            environment['BILLING_ENABLED'] = 'true';
            final response = await startRun(admission: admission);
            expect(response.statusCode, HttpStatus.badRequest);
            expect(await response.json(), {
              'error': 'billing_admission_required',
            });
            expect(requests, isEmpty);
            await expectRunNotStarted();
          },
        );
      }

      for (final token in [null, 'invalid-worker-key']) {
        test(
          'rejects a Firebase member without a valid worker key: $token',
          () async {
            final response = await startRun(
              uid: 'user-123',
              bearerToken: token,
            );
            expect(response.statusCode, HttpStatus.forbidden);
            expect(requests, isEmpty);
            await expectRunNotStarted();
          },
        );
      }

      for (final status in BuildJobStatus.values.where(
        (status) => status != BuildJobStatus.IN_PROGRESS,
      )) {
        test('rejects worker run creation for $status', () async {
          await db
              .update(db.buildJobs)
              .write(BuildJobsCompanion(status: Value(status)));
          final response = await startRun();
          expect(response.statusCode, HttpStatus.conflict);
          expect(requests, isEmpty);
          await expectRunNotStarted();
        });
      }

      test('accepts an authenticated worker for an in-progress job', () async {
        expect((await startRun()).statusCode, HttpStatus.ok);
        expect(
          await db.buildRunDao.getBuildRun('job-check', 'run-check'),
          isNotNull,
        );
      });

      test('rolls back if the job stops before the run is inserted', () async {
        onRepositoryLookup = () async {
          await db
              .update(db.buildJobs)
              .write(
                const BuildJobsCompanion(status: Value(BuildJobStatus.FAILURE)),
              );
        };
        expect((await startRun()).statusCode, HttpStatus.conflict);
        expect(checkRequests(), isEmpty);
        await expectRunNotStarted();
      });
    });

    for (final checkRunId in [null, '']) {
      test('creates and saves a Check when the ID is $checkRunId', () async {
        await db
            .update(db.buildJobs)
            .write(
              BuildJobsCompanion(checkRunId: Value(checkRunId)),
            );

        final response = await startRun();

        expect(response.statusCode, HttpStatus.ok);
        expect(requests.map((request) => request.method), [
          'GET',
          'POST',
          'POST',
        ]);
        expect(requests.map((request) => request.url.toString()), [
          'https://api.github.com/repos/org/mobile/installation',
          'https://api.github.com/app/installations/98765/access_tokens',
          'https://api.github.com/repos/org/mobile/check-runs',
        ]);
        final request = checkRequests().single;
        expect(request.method, 'POST');
        expect(request.headers['authorization'], 'Bearer test-token');
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
      expect((await db.buildJobDao.getBuildJob('job-check'))!.runCount, 3);
    });

    test('rolls back the build run when Check creation is rejected', () async {
      createStatus = HttpStatus.forbidden;

      final response = await startRun();

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(checkRequests().single.method, 'POST');
      final stored = (await db.buildJobDao.getBuildJob('job-check'))!;
      expect(stored.checkRunId, isNull);
      await expectRunNotStarted();

      createStatus = HttpStatus.created;
      expect((await startRun()).statusCode, HttpStatus.ok);
      expect((await db.buildJobDao.getBuildJob('job-check'))!.runCount, 3);
    });

    test(
      'rolls back the run and preserves the Check if updating fails',
      () async {
        await db
            .update(db.buildJobs)
            .write(
              const BuildJobsCompanion(
                checkRunId: Value('99999'),
                commitSha: Value(null),
              ),
            );
        updateStatus = HttpStatus.internalServerError;

        expect((await startRun()).statusCode, HttpStatus.internalServerError);
        expect(checkRequests().single.method, 'PATCH');
        expect(
          (await db.buildJobDao.getBuildJob('job-check'))!.checkRunId,
          '99999',
        );
        await expectRunNotStarted();
      },
    );

    test('rejects a job with no installation before starting a run', () async {
      await db
          .update(db.buildJobs)
          .write(
            const BuildJobsCompanion(installationId: Value(null)),
          );

      expect((await startRun()).statusCode, HttpStatus.badRequest);
      expect(requests, isEmpty);
      await expectRunNotStarted();
    });

    test('rejects a nonnumeric installation before starting a run', () async {
      await db
          .update(db.buildJobs)
          .write(
            const BuildJobsCompanion(installationId: Value('invalid')),
          );

      expect((await startRun()).statusCode, HttpStatus.badRequest);
      expect(requests, isEmpty);
      await expectRunNotStarted();
    });

    test('rejects a nonpositive installation before starting a run', () async {
      await db
          .update(db.buildJobs)
          .write(
            const BuildJobsCompanion(installationId: Value('0')),
          );

      expect((await startRun()).statusCode, HttpStatus.badRequest);
      expect(requests, isEmpty);
      await expectRunNotStarted();
    });

    test('requires a commit SHA when creating a Check', () async {
      await db
          .update(db.buildJobs)
          .write(
            const BuildJobsCompanion(commitSha: Value(null)),
          );

      expect((await startRun()).statusCode, HttpStatus.badRequest);
      expect(requests, isEmpty);
      await expectRunNotStarted();
    });

    test('rejects an invalid saved Check ID', () async {
      await db
          .update(db.buildJobs)
          .write(
            const BuildJobsCompanion(checkRunId: Value('invalid')),
          );

      expect((await startRun()).statusCode, HttpStatus.badRequest);
      expect(requests, isEmpty);
      await expectRunNotStarted();
    });

    test(
      'does not authorize a legacy installation without a connection',
      () async {
        final team = (await db.teamDao.getTeam('team-xyz'))!;
        await db.teamDao.updateTeam(team.copyWith(installationIds: [98765]));
        await db.delete(db.gitHubConnections).go();

        expect((await startRun()).statusCode, HttpStatus.forbidden);
        expect(requests, isEmpty);
        await expectRunNotStarted();
      },
    );

    test('rejects a connection belonging to another team', () async {
      final team = (await db.teamDao.getTeam('team-xyz'))!;
      await db.teamDao.createTeamAndMember(
        team.copyWith(id: 'other-team'),
        'other-user',
      );
      await expectConnectionRejected(connection.copyWith(teamId: 'other-team'));
    });

    test('rejects a suspended connection', () async {
      await expectConnectionRejected(
        connection.copyWith(status: GitHubConnectionStatus.suspended),
      );
    });

    test('rejects a removed connection', () async {
      await expectConnectionRejected(
        connection.copyWith(status: GitHubConnectionStatus.removed),
      );
    });

    test('rejects a connection for a different API host', () async {
      await expectConnectionRejected(
        connection.copyWith(githubApiBaseUrl: 'https://other.example/api/v3'),
      );
    });

    test('rejects a connection for a different App', () async {
      await expectConnectionRejected(connection.copyWith(githubAppId: 999));
    });

    test(
      'rejects a repository belonging to a different installation',
      () async {
        repositoryInstallationId = 54321;

        expect((await startRun()).statusCode, HttpStatus.forbidden);
        expect(requests.single.url.path, '/repos/org/mobile/installation');
        await expectRunNotStarted();
      },
    );

    test(
      'returns an error when GitHub rejects the repository lookup',
      () async {
        lookupStatus = HttpStatus.forbidden;

        expect((await startRun()).statusCode, HttpStatus.internalServerError);
        expect(requests.single.url.path, '/repos/org/mobile/installation');
        await expectRunNotStarted();
      },
    );

    test('rolls back when GitHub rejects token issuance', () async {
      tokenStatus = HttpStatus.forbidden;

      expect((await startRun()).statusCode, HttpStatus.internalServerError);
      expect(requests.map((request) => request.url.path), [
        '/repos/org/mobile/installation',
        '/app/installations/98765/access_tokens',
      ]);
      await expectRunNotStarted();
    });

    test('rejects an empty token before creating a Check', () async {
      token = ' ';

      expect((await startRun()).statusCode, HttpStatus.internalServerError);
      expect(checkRequests(), isEmpty);
      await expectRunNotStarted();
    });

    test('rolls back when GitHub does not finish creating a Check', () async {
      pendingCheck = Completer<http.Response>();
      try {
        expect((await startRun()).statusCode, HttpStatus.internalServerError);
        await expectRunNotStarted();
        expect(
          (await db.buildJobDao.getBuildJob('job-check'))!.checkRunId,
          isNull,
        );
      } finally {
        pendingCheck!.complete(
          http.Response('{"id":99999}', HttpStatus.created),
        );
      }
    });

    test('uses GitHub for the former dummy installation', () async {
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(installationId: 12345678),
          );
      await db
          .update(db.buildJobs)
          .write(
            const BuildJobsCompanion(installationId: Value('12345678')),
          );
      repositoryInstallationId = 12345678;

      expect((await startRun()).statusCode, HttpStatus.ok);
      expect(requests.map((request) => request.url.path), [
        '/repos/org/mobile/installation',
        '/app/installations/12345678/access_tokens',
        '/repos/org/mobile/check-runs',
      ]);
      expect(
        checkRequests().single.headers['authorization'],
        'Bearer test-token',
      );
    });

    test('rechecks the connection before reusing a saved Check', () async {
      expect((await startRun()).statusCode, HttpStatus.ok);
      requests.clear();
      await db.delete(db.gitHubConnections).go();

      expect((await startRun(runId: 'rerun')).statusCode, HttpStatus.forbidden);
      expect(requests, isEmpty);
      expect((await db.buildJobDao.getBuildJob('job-check'))!.runCount, 3);
      expect(await db.buildRunDao.getBuildRun('job-check', 'rerun'), isNull);
    });

    test(
      'uses the normalized operator URL instead of the saved job URL',
      () async {
        environment['GITHUB_API_BASE_URL'] =
            'https://ghe.example:8443/api/v3///';
        await db
            .update(db.gitHubConnections)
            .replace(
              connection.copyWith(
                githubApiBaseUrl: 'https://ghe.example:8443/api/v3',
              ),
            );

        expect((await startRun()).statusCode, HttpStatus.ok);
        expect(requests.map((request) => request.url.toString()), [
          'https://ghe.example:8443/api/v3/repos/org/mobile/installation',
          'https://ghe.example:8443/api/v3/app/installations/98765/access_tokens',
          'https://ghe.example:8443/api/v3/repos/org/mobile/check-runs',
        ]);
      },
    );

    test(
      'rejects missing GitHub configuration before starting a run',
      () async {
        environment.remove('GITHUB_APP_ID');

        expect((await startRun()).statusCode, HttpStatus.internalServerError);
        expect(requests, isEmpty);
        await expectRunNotStarted();
      },
    );

    test('allows a team member without an internal API key', () async {
      final response = await startRun(uid: 'user-123', bearerToken: null);

      expect(response.statusCode, HttpStatus.ok);
      expect(checkRequests(), hasLength(1));
    });

    test('rejects an unauthenticated caller', () async {
      expect(
        (await startRun(bearerToken: null)).statusCode,
        HttpStatus.unauthorized,
      );
      expect(requests, isEmpty);
      await expectRunNotStarted();
    });

    test('rejects a caller outside the team', () async {
      final response = await startRun(uid: 'outsider', bearerToken: null);

      expect(response.statusCode, HttpStatus.forbidden);
      expect(requests, isEmpty);
      await expectRunNotStarted();
    });
  });

  group('GET /builds/<id>/runs', () {
    test(
      'responds with 200 OK and returns a list of build runs when authorized',
      () async {
        final now = _getNormalizedNow();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
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
      configure: (context) {
        context.provide<DriftBuildJob>(
          databaseFailureJob.copyWith(
            installationId: const Value('98765'),
            commitSha: const Value('abc123'),
          ),
        );
        context.provide<Map<String, String>>({
          'GITHUB_APP_ID': '123456',
          'GITHUB_API_BASE_URL': 'https://api.github.com',
        });
      },
    ),
  ]);
}
