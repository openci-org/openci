import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../../routes/webhooks/_middleware.dart' as webhooks;
import '../../../../../routes/webhooks/tasks/[id]/complete.dart' as route;
import '../../../../../routes/builds/[id]/runs/index.dart' as runs_route;
import '../../../../helpers/github_app_test_key.dart';

void main() {
  group('POST /webhooks/tasks/[id]/complete', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns 405 for methods other than POST', () async {
      final response = await _request(
        db: db,
        taskId: 'task-1',
        jobs: const [],
        method: HttpMethod.get,
      );

      expect(response.statusCode, HttpStatus.methodNotAllowed);
    });

    test('creates queued build jobs and completes the task', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');

      final response = await _request(
        db: db,
        taskId: 'task-1',
        jobs: [_plan.toJson()],
      );

      expect(response.statusCode, HttpStatus.ok);
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['jobs_created'], 1);
      expect(body['job_ids'], hasLength(1));
      expect(body['already_completed'], isFalse);

      final task = await db.webhookTaskDao.getWebhookTask('task-1');
      expect(task?.status, 'completed');

      final jobs = await db.select(db.buildJobs).get();
      expect(jobs, hasLength(1));
      expect(jobs.single.status, BuildJobStatus.QUEUED);
      expect(jobs.single.owner, _plan.owner);
      expect(jobs.single.repo, _plan.repo);
      expect(jobs.single.workflowName, _plan.workflowName);
      expect(jobs.single.installationId, _plan.installationId);
      expect(jobs.single.runCount, 0);
    });

    test('completes the task when jobs is empty', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');

      final response = await _request(
        db: db,
        taskId: 'task-1',
        jobs: const [],
      );

      expect(response.statusCode, HttpStatus.ok);
      final body = await response.json() as Map<String, dynamic>;
      expect(body['jobs_created'], 0);
      expect(body['job_ids'], isEmpty);
      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        'completed',
      );
      expect(await db.select(db.buildJobs).get(), isEmpty);
    });

    test('reuses a queued Check when the first run starts', () async {
      final directory = await Directory.systemTemp.createTemp(
        'queued_check_route_',
      );
      final keyFile = File.fromUri(directory.uri.resolve('key.pem'));
      await keyFile.writeAsString(testRsaPrivateKey);
      addTearDown(() => directory.delete(recursive: true));
      final environment = {
        'GITHUB_APP_ID': '123456',
        'GITHUB_PRIVATE_KEY_PATH': keyFile.path,
        'GITHUB_API_BASE_URL': 'https://api.github.test',
      };
      final checkRequests = <http.Request>[];
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/access_tokens')) {
          return http.Response('{"token":"test-token"}', HttpStatus.created);
        }
        checkRequests.add(request);
        return http.Response(
          '{"id":99999}',
          request.method == 'POST' ? HttpStatus.created : HttpStatus.ok,
        );
      });
      addTearDown(client.close);
      await _insertTask(db, id: 'task-1', status: 'processing');

      final response = await _request(
        db: db,
        taskId: 'task-1',
        jobs: [_plan.toJson()],
        environment: environment,
        client: client,
      );

      expect(response.statusCode, HttpStatus.ok);
      final job = (await db.select(db.buildJobs).get()).single;
      expect(job.status, BuildJobStatus.QUEUED);
      expect(job.checkRunId, '99999');
      expect(job.runCount, 0);
      expect(await db.select(db.buildRuns).get(), isEmpty);
      expect(
        jsonDecode(checkRequests.single.body),
        containsPair('status', 'queued'),
      );

      await (db.update(
        db.buildJobs,
      )..where((row) => row.id.equals(job.id))).write(
        const BuildJobsCompanion(status: Value(BuildJobStatus.IN_PROGRESS)),
      );
      final claimed = (await db.buildJobDao.getBuildJob(job.id))!;
      final runContext = TestRequestContext(
        path: '/builds/${job.id}/runs',
        method: HttpMethod.post,
        body: jsonEncode({'id': 'run-1'}),
      );
      runContext.provide<AppDatabase>(db);
      runContext.provide<DriftBuildJob>(claimed);
      runContext.provide<Map<String, String>>(environment);
      runContext.provide<http.Client>(client);

      final runResponse = await runs_route.onRequest(
        runContext.context,
        job.id,
      );

      expect(runResponse.statusCode, HttpStatus.ok);
      expect(checkRequests.map((request) => request.method), ['POST', 'PATCH']);
      expect(
        checkRequests.last.url.path,
        '/repos/openci-owner/openci-repo/check-runs/99999',
      );
      final body = jsonDecode(checkRequests.last.body) as Map<String, dynamic>;
      expect(DateTime.parse(body.remove('started_at') as String).isUtc, isTrue);
      expect(body, {'status': 'in_progress'});
      expect((await db.buildJobDao.getBuildJob(job.id))!.checkRunId, '99999');
      expect(await db.select(db.buildRuns).get(), hasLength(1));
    });

    test('returns 400 when jobs is not a list', () async {
      final response = await _requestWithBody(
        db: db,
        taskId: 'task-1',
        body: jsonEncode({'jobs': 'invalid'}),
      );

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('returns 404 when the task does not exist', () async {
      final response = await _request(
        db: db,
        taskId: 'missing-task',
        jobs: const [],
      );

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('returns 409 when the task is not processing', () async {
      await _insertTask(db, id: 'task-1', status: 'pending');

      final response = await _request(
        db: db,
        taskId: 'task-1',
        jobs: const [],
      );

      expect(response.statusCode, HttpStatus.conflict);
      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        'pending',
      );
    });

    test(
      'does not create duplicate jobs when completion is repeated',
      () async {
        await _insertTask(db, id: 'task-1', status: 'processing');

        final firstResponse = await _request(
          db: db,
          taskId: 'task-1',
          jobs: [_plan.toJson()],
        );
        final secondResponse = await _request(
          db: db,
          taskId: 'task-1',
          jobs: [_plan.toJson()],
        );

        expect(firstResponse.statusCode, HttpStatus.ok);
        expect(secondResponse.statusCode, HttpStatus.ok);
        final secondBody = await secondResponse.json() as Map<String, dynamic>;
        expect(secondBody['jobs_created'], 0);
        expect(secondBody['already_completed'], isTrue);
        expect(await db.select(db.buildJobs).get(), hasLength(1));
      },
    );
  });
}

const _plan = BuildJobPlan(
  owner: 'openci-owner',
  repo: 'openci-repo',
  workflowName: 'Dashboard CI',
  workflowFileName: 'dashboard_ci.dart',
  teamId: 'team-1',
  commitSha: 'commit-sha-1',
  branch: 'develop',
  runsOn: 'macos-latest',
  githubBaseUrl: 'https://github.com',
  installationId: '98765',
);

Future<void> _insertTask(
  AppDatabase db, {
  required String id,
  required String status,
}) async {
  final now = DateTime.now().toUtc();
  await db.webhookTaskDao.insertWebhookTask(
    DriftWebhookTask(
      id: id,
      deliveryId: 'delivery-$id',
      eventType: 'push',
      payload: '{}',
      status: status,
      retryCount: 0,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<Response> _request({
  required AppDatabase db,
  required String taskId,
  required List<Map<String, dynamic>> jobs,
  HttpMethod method = HttpMethod.post,
  Map<String, String> environment = const {},
  http.Client? client,
}) {
  return _requestWithBody(
    db: db,
    taskId: taskId,
    method: method,
    body: jsonEncode({'jobs': jobs}),
    environment: environment,
    client: client,
  );
}

Future<Response> _requestWithBody({
  required AppDatabase db,
  required String taskId,
  required String body,
  HttpMethod method = HttpMethod.post,
  Map<String, String> environment = const {},
  http.Client? client,
}) async {
  const validator = InternalApiKeyValidator.forTesting(
    environment: {'INTERNAL_API_KEY': 'test-internal-key'},
  );
  final context = TestRequestContext(
    path: '/webhooks/tasks/$taskId/complete',
    method: method,
    headers: {'Authorization': 'Bearer test-internal-key'},
    body: body,
  );
  context.provide<AppDatabase>(db);
  context.provide<InternalApiKeyValidator>(validator);
  context.provide<Map<String, String>>(environment);
  if (client != null) context.provide<http.Client>(client);
  final handler = webhooks.middleware(
    (context) => route.onRequest(context, taskId),
  );
  return await handler(context.context);
}
