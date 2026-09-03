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

    tearDown(() => db.close());

    test('requires the internal API identity', () async {
      await _insertTask(db, status: 'processing');

      final unauthenticated = await _completeTask(
        db: db,
        uid: null,
        jobs: const [],
      );
      final regularUser = await _completeTask(
        db: db,
        uid: 'user-123',
        jobs: const [],
      );

      expect(unauthenticated.statusCode, equals(HttpStatus.unauthorized));
      expect(regularUser.statusCode, equals(HttpStatus.forbidden));
    });

    test('returns 404 when the webhook task does not exist', () async {
      final response = await _completeTask(
        db: db,
        uid: 'system-job-processor',
        jobs: const [],
      );

      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('returns 400 when jobs is not a list', () async {
      await _insertTask(db, status: 'processing');

      final response = await _request(
        db: db,
        uid: 'system-job-processor',
        body: jsonEncode({'jobs': 'invalid'}),
      );

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(await db.select(db.buildJobs).get(), isEmpty);
    });

    test('stores BuildJobs and completes the task atomically', () async {
      await _insertTask(
        db,
        status: 'processing',
        leaseUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
        errorMessage: 'old failure',
      );
      final beforeRequest = DateTime.now().toUtc();

      final response = await _completeTask(
        db: db,
        uid: 'system-job-processor',
        jobs: [_buildJobPlan()],
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['jobs_created'], equals(1));
      expect(body['job_ids'], hasLength(1));
      expect(body['already_completed'], isFalse);

      final savedTask = await db.webhookTaskDao.getWebhookTask('task-1');
      expect(savedTask?.status, equals('completed'));
      expect(savedTask?.leaseUntil, isNull);
      expect(savedTask?.nextRetryAt, isNull);
      expect(savedTask?.errorMessage, isNull);

      final jobs = await db.select(db.buildJobs).get();
      expect(jobs, hasLength(1));
      expect(jobs.single.id, equals((body['job_ids'] as List).single));
      expect(jobs.single.id, isNotEmpty);
      expect(jobs.single.status, equals(BuildJobStatus.QUEUED));
      expect(jobs.single.runCount, isZero);
      expect(jobs.single.installationId, equals('98765'));
      expect(
        jobs.single.createdAt.isBefore(
          beforeRequest.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(jobs.single.updatedAt, equals(jobs.single.createdAt));
    });

    test('rejects persistence fields owned by the server', () async {
      await _insertTask(db, status: 'processing');

      final response = await _completeTask(
        db: db,
        uid: 'system-job-processor',
        jobs: [
          {..._buildJobPlan(), 'id': 'planner-generated-id'},
        ],
      );

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(await db.select(db.buildJobs).get(), isEmpty);
      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        equals('processing'),
      );
    });

    test('accepts an empty job list and completes the task', () async {
      await _insertTask(db, status: 'processing');

      final response = await _completeTask(
        db: db,
        uid: 'system-job-processor',
        jobs: const [],
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        equals('completed'),
      );
      expect(await db.select(db.buildJobs).get(), isEmpty);
    });

    test('does not create jobs when the task is already completed', () async {
      await _insertTask(db, status: 'processing');
      final firstResponse = await _completeTask(
        db: db,
        uid: 'system-job-processor',
        jobs: [_buildJobPlan(workflowName: 'Original CI')],
      );
      final firstBody = await firstResponse.json() as Map<String, dynamic>;
      final originalJobId = (firstBody['job_ids'] as List).single;

      final response = await _completeTask(
        db: db,
        uid: 'system-job-processor',
        jobs: [_buildJobPlan(workflowName: 'Duplicate CI')],
      );

      expect(firstResponse.statusCode, equals(HttpStatus.ok));
      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['jobs_created'], equals(0));
      expect(body['job_ids'], isEmpty);
      expect(body['already_completed'], isTrue);
      final jobs = await db.select(db.buildJobs).get();
      expect(jobs.map((job) => job.id), equals([originalJobId]));
      expect(jobs.single.workflowName, equals('Original CI'));
    });

    test('rolls back task completion when BuildJob insertion fails', () async {
      await _insertTask(db, status: 'processing');
      await db.customStatement('''
        CREATE TRIGGER reject_build_job_insert
        BEFORE INSERT ON build_jobs
        BEGIN
          SELECT RAISE(ABORT, 'forced build job insertion failure');
        END;
      ''');

      final response = await _completeTask(
        db: db,
        uid: 'system-job-processor',
        jobs: [_buildJobPlan()],
      );

      expect(response.statusCode, equals(HttpStatus.internalServerError));
      expect(await db.select(db.buildJobs).get(), isEmpty);
      final task = await db.webhookTaskDao.getWebhookTask('task-1');
      expect(task?.status, equals('retry_waiting'));
      expect(task?.retryCount, equals(1));
    });
  });
}

Map<String, Object?> _buildJobPlan({String workflowName = 'Dashboard CI'}) {
  return {
    'owner': 'openci-owner',
    'repo': 'openci-repo',
    'workflowName': workflowName,
    'workflowFileName': 'dashboard_ci.dart',
    'teamId': 'team-1',
    'commitSha': 'commit-sha-1',
    'commitMessage': 'Add lightweight BuildJob plans',
    'branch': 'main',
    'runsOn': 'macos-latest',
    'githubBaseUrl': 'https://github.com',
    'installationId': '98765',
  };
}

Future<void> _insertTask(
  AppDatabase db, {
  required String status,
  DateTime? leaseUntil,
  String? errorMessage,
}) {
  final now = DateTime.now().toUtc();
  return db.webhookTaskDao.insertWebhookTask(
    DriftWebhookTask(
      id: 'task-1',
      deliveryId: 'delivery-1',
      eventType: 'push',
      payload: '{}',
      status: status,
      leaseUntil: leaseUntil,
      retryCount: 0,
      errorMessage: errorMessage,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<Response> _completeTask({
  required AppDatabase db,
  required String? uid,
  required List<Map<String, Object?>> jobs,
}) {
  return _request(db: db, uid: uid, body: jsonEncode({'jobs': jobs}));
}

Future<Response> _request({
  required AppDatabase db,
  required String? uid,
  required String body,
}) async {
  final context = TestRequestContext(
    path: '/webhooks/tasks/task-1/complete',
    method: HttpMethod.post,
    body: body,
  );
  context.provide<AppDatabase>(db);
  context.provide<String?>(uid);
  return route.onRequest(context.context, 'task-1');
}
