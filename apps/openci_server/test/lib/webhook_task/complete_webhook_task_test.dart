import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/complete_webhook_task.dart';
import 'package:openci_server/webhook_task/webhook_task_transition_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../helpers/github_app_test_key.dart';

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
    late Map<String, String> environment;
    late MockClient client;
    late List<http.Request> checkRequests;
    Future<void> Function()? beforeCreate;
    var failedWorkflow = '';

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final directory = await Directory.systemTemp.createTemp('queued_checks_');
      final keyFile = File.fromUri(directory.uri.resolve('key.pem'));
      await keyFile.writeAsString(testRsaPrivateKey);
      addTearDown(() => directory.delete(recursive: true));
      environment = {
        'GITHUB_APP_ID': '123456',
        'GITHUB_PRIVATE_KEY_PATH': keyFile.path,
        'GITHUB_API_BASE_URL': 'https://api.github.test',
      };
      checkRequests = [];
      beforeCreate = null;
      failedWorkflow = '';
      client = MockClient((request) async {
        if (request.url.path.endsWith('/access_tokens')) {
          return http.Response('{"token":"test-token"}', HttpStatus.created);
        }
        await beforeCreate?.call();
        checkRequests.add(request);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body['name'] == failedWorkflow) {
          return http.Response('Unavailable', HttpStatus.serviceUnavailable);
        }
        return http.Response(
          jsonEncode({'id': 1000 + checkRequests.length}),
          HttpStatus.created,
        );
      });
      addTearDown(client.close);
    });

    tearDown(() async {
      await db.close();
    });

    Future<CompleteWebhookTaskResult> completeTask({
      required String taskId,
      required List<BuildJobPlan> jobs,
    }) => completeWebhookTask(
      db: db,
      taskId: taskId,
      jobs: jobs,
      environment: environment,
      client: client,
    );

    test('creates jobs and completes a processing task', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');

      final result = await completeTask(
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
      expect(jobs.single.checkRunId, '1001');
    });

    test(
      'creates a queued Check for every job before any run starts',
      () async {
        await _insertTask(db, id: 'task-1', status: 'processing');
        final plans = List.generate(
          5,
          (index) => _plan.copyWith(workflowName: 'CI $index'),
        );

        final result = await completeTask(taskId: 'task-1', jobs: plans);

        expect(result.jobIds, hasLength(5));
        expect(checkRequests, hasLength(5));
        expect(await db.select(db.buildRuns).get(), isEmpty);
        for (final (index, request) in checkRequests.indexed) {
          expect(request.method, 'POST');
          expect(
            request.url.path,
            '/repos/openci-owner/openci-repo/check-runs',
          );
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final job = (await db.buildJobDao.getBuildJob(
            body['external_id'] as String,
          ))!;
          expect(body, {
            'name': job.workflowName,
            'head_sha': _plan.commitSha,
            'external_id': job.id,
            'status': 'queued',
          });
          expect(job.checkRunId, '${1001 + index}');
          expect(job.status, BuildJobStatus.QUEUED);
          expect(job.runCount, 0);
        }
      },
    );

    test('keeps all jobs and other Checks when one creation fails', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');
      failedWorkflow = 'Failing CI';

      await completeTask(
        taskId: 'task-1',
        jobs: [
          _plan,
          _plan.copyWith(workflowName: failedWorkflow),
          _plan,
        ],
      );

      final jobs = await db.select(db.buildJobs).get();
      expect(jobs, hasLength(3));
      expect(checkRequests, hasLength(3));
      expect(jobs.where((job) => job.checkRunId != null), hasLength(2));
      expect(
        jobs
            .singleWhere((job) => job.workflowName == failedWorkflow)
            .checkRunId,
        isNull,
      );
      expect(jobs.every((job) => job.status == BuildJobStatus.QUEUED), isTrue);
      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))!.status,
        'completed',
      );
    });

    test('does not expose queued jobs until Check IDs are saved', () async {
      await db.close();
      final directory = await Directory.systemTemp.createTemp(
        'queued_check_visibility_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final databaseFile = File.fromUri(directory.uri.resolve('test.sqlite'));
      db = AppDatabase(NativeDatabase(databaseFile));
      await _insertTask(db, id: 'task-1', status: 'processing');
      final observer = AppDatabase(NativeDatabase(databaseFile));
      addTearDown(observer.close);
      expect(await observer.buildJobDao.getQueuedJobs(), isEmpty);
      final outsideTransaction = Zone.current;
      final visibleDuringCreation = <List<DriftBuildJob>>[];
      beforeCreate = () async {
        visibleDuringCreation.add(
          await outsideTransaction.run(
            observer.buildJobDao.getQueuedJobs,
          ),
        );
      };

      await completeTask(taskId: 'task-1', jobs: const [_plan, _plan]);

      expect(visibleDuringCreation, hasLength(2));
      expect(visibleDuringCreation, everyElement(isEmpty));
      final queued = await observer.buildJobDao.getQueuedJobs();
      expect(queued, hasLength(2));
      expect(queued.every((job) => job.checkRunId != null), isTrue);
    });

    test(
      'skips Checks for jobs without GitHub installation or commit metadata',
      () async {
        await _insertTask(db, id: 'task-1', status: 'processing');

        await completeTask(
          taskId: 'task-1',
          jobs: [
            for (final installationId in ['', '12345678'])
              _plan.copyWith(installationId: installationId),
            _plan.copyWith(commitSha: ''),
          ],
        );

        expect(checkRequests, isEmpty);
        final jobs = await db.select(db.buildJobs).get();
        expect(jobs, hasLength(3));
        expect(jobs.every((job) => job.checkRunId == null), isTrue);
      },
    );

    test('completes a processing task without jobs', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');

      final result = await completeTask(
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
        completeTask(taskId: 'missing-task', jobs: const []),
        throwsA(isA<WebhookTaskNotFoundException>()),
      );
    });

    test('throws without changing a task that is not processing', () async {
      await _insertTask(db, id: 'task-1', status: 'pending');

      await expectLater(
        completeTask(taskId: 'task-1', jobs: const [_plan]),
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
      await completeTask(taskId: 'task-1', jobs: const [_plan]);

      final result = await completeTask(
        taskId: 'task-1',
        jobs: const [_plan],
      );

      expect(result.jobIds, isEmpty);
      expect(result.alreadyCompleted, isTrue);
      expect(await db.select(db.buildJobs).get(), hasLength(1));
      expect(checkRequests, hasLength(1));
    });

    test('rolls back the task update when job insertion fails', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');
      final invalidPlan = _plan.copyWith(matrix: {'invalid': Object()});

      await expectLater(
        completeTask(taskId: 'task-1', jobs: [_plan, invalidPlan]),
        throwsA(isA<JsonUnsupportedObjectError>()),
      );

      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        'processing',
      );
      expect(await db.select(db.buildJobs).get(), isEmpty);
      expect(checkRequests, isEmpty);
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
