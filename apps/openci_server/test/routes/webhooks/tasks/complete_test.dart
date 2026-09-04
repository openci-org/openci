import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/webhooks/tasks/[id]/complete.dart' as route;

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
      final context = TestRequestContext(
        path: '/webhooks/tasks/task-1/complete',
        method: HttpMethod.get,
      );

      final response = await route.onRequest(context.context, 'task-1');

      expect(response.statusCode, HttpStatus.methodNotAllowed);
    });

    test('returns 401 when unauthenticated', () async {
      final response = await _request(
        db: db,
        taskId: 'task-1',
        uid: null,
        jobs: const [],
      );

      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test(
      'returns 403 when authenticated without the internal API key',
      () async {
        final response = await _request(
          db: db,
          taskId: 'task-1',
          uid: 'firebase-user',
          jobs: const [],
        );

        expect(response.statusCode, HttpStatus.forbidden);
      },
    );

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
  String? uid = 'system-job-processor',
}) {
  return _requestWithBody(
    db: db,
    taskId: taskId,
    uid: uid,
    body: jsonEncode({'jobs': jobs}),
  );
}

Future<Response> _requestWithBody({
  required AppDatabase db,
  required String taskId,
  required String body,
  String? uid = 'system-job-processor',
}) async {
  final context = TestRequestContext(
    path: '/webhooks/tasks/$taskId/complete',
    method: HttpMethod.post,
    body: body,
  );
  context.provide<AppDatabase>(db);
  context.provide<String?>(uid);
  return await route.onRequest(context.context, taskId);
}
