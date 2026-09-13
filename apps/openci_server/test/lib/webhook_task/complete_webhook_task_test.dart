import 'dart:convert';

import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/complete_webhook_task.dart';
import 'package:openci_server/webhook_task/webhook_task_transition_exception.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('parseBuildJobPlans', () {
    test('parses every job in the payload', () {
      final plans = parseBuildJobPlans({
        'jobs': [
          _plan.toJson(),
          _plan.copyWith(workflowName: 'Release').toJson(),
        ],
      });

      expect(plans, hasLength(2));
      expect(plans.first, _plan);
      expect(plans.last.workflowName, 'Release');
    });

    test('accepts an empty jobs list', () {
      expect(parseBuildJobPlans({'jobs': <Object?>[]}), isEmpty);
    });

    test('rejects a jobs value that is not a list', () {
      expect(
        () => parseBuildJobPlans({'jobs': 'invalid'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a job that is not an object', () {
      expect(
        () => parseBuildJobPlans({
          'jobs': ['invalid'],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('jobs[0]'),
          ),
        ),
      );
    });

    test('rejects an invalid BuildJobPlan', () {
      expect(
        () => parseBuildJobPlans({
          'jobs': [
            {'owner': 'openci-owner'},
          ],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('jobs[0]'),
          ),
        ),
      );
    });
  });

  group('completeWebhookTask', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('creates jobs and completes a processing task', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');

      final result = await completeWebhookTask(
        db: db,
        taskId: 'task-1',
        jobs: const [_plan],
      );

      expect(result.jobIds, hasLength(1));
      expect(result.alreadyCompleted, isFalse);
      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        'completed',
      );

      final jobs = await db.select(db.buildJobs).get();
      expect(jobs, hasLength(1));
      expect(jobs.single.id, result.jobIds.single);
      expect(jobs.single.status, BuildJobStatus.QUEUED);
      expect(jobs.single.owner, _plan.owner);
    });

    test('completes a processing task without jobs', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');

      final result = await completeWebhookTask(
        db: db,
        taskId: 'task-1',
        jobs: const [],
      );

      expect(result.jobIds, isEmpty);
      expect(result.alreadyCompleted, isFalse);
      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        'completed',
      );
      expect(await db.select(db.buildJobs).get(), isEmpty);
    });

    test('throws when the task does not exist', () async {
      await expectLater(
        completeWebhookTask(db: db, taskId: 'missing-task', jobs: const []),
        throwsA(isA<WebhookTaskNotFoundException>()),
      );
    });

    test('throws without changing a task that is not processing', () async {
      await _insertTask(db, id: 'task-1', status: 'pending');

      await expectLater(
        completeWebhookTask(db: db, taskId: 'task-1', jobs: const [_plan]),
        throwsA(
          isA<InvalidWebhookTaskStatusException>().having(
            (error) => error.status,
            'status',
            'pending',
          ),
        ),
      );

      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        'pending',
      );
      expect(await db.select(db.buildJobs).get(), isEmpty);
    });

    test('returns already completed without creating duplicate jobs', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');
      await completeWebhookTask(db: db, taskId: 'task-1', jobs: const [_plan]);

      final result = await completeWebhookTask(
        db: db,
        taskId: 'task-1',
        jobs: const [_plan],
      );

      expect(result.jobIds, isEmpty);
      expect(result.alreadyCompleted, isTrue);
      expect(await db.select(db.buildJobs).get(), hasLength(1));
    });

    test('rolls back the task update when job insertion fails', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');
      final invalidPlan = _plan.copyWith(matrix: {'invalid': Object()});

      await expectLater(
        completeWebhookTask(db: db, taskId: 'task-1', jobs: [invalidPlan]),
        throwsA(isA<JsonUnsupportedObjectError>()),
      );

      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        'processing',
      );
      expect(await db.select(db.buildJobs).get(), isEmpty);
    });
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
