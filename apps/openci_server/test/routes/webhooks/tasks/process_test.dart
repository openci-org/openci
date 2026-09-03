import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/github_app_test_key.dart';
import '../../../../routes/webhooks/tasks/[id]/process.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  group('POST /webhooks/tasks/[id]/process', () {
    late RequestContext context;
    late Request request;
    late AppDatabase db;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      db = _MockAppDatabase();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<AppDatabase>()).thenReturn(db);
    });

    test('returns 401 Unauthorized when not authenticated', () async {
      when(() => context.read<String?>()).thenReturn(null);

      final response = await route.onRequest(context, 'task-1');

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });
  });

  group('webhook task processing', () {
    late AppDatabase db;
    late Directory tempDirectory;
    late Map<String, String> environment;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.now().toUtc();
      await db
          .into(db.teams)
          .insert(
            DriftTeam(
              id: 'team-123',
              name: 'Test Team',
              installationIds: const [98765],
              aiEnabled: false,
              runNumber: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );

      tempDirectory = Directory.systemTemp.createTempSync(
        'openci-webhook-process-test-',
      );
      final privateKeyFile = File(
        p.join(tempDirectory.path, 'private-key.pem'),
      )..writeAsStringSync(testRsaPrivateKey);

      environment = {
        'GITHUB_APP_ID': '12345',
        'GITHUB_PRIVATE_KEY_PATH': privateKeyFile.path,
        'GITHUB_API_BASE_URL': 'https://api.github.com',
      };
    });

    tearDown(() async {
      await db.close();
      tempDirectory.deleteSync(recursive: true);
    });

    test('creates a queued BuildJob and completes the task', () async {
      final task = await _insertPushTask(db, id: 'matching-task');
      final client = _githubClientWithWorkflow(
        '''
import 'package:genuine_ci/genuine_ci.dart';

Future<void> main() async {
  await GenuineCI.init(
    workflowName: 'Dashboard CI',
    ciTrigger: CiTrigger.push(branch: 'main'),
  );
}
''',
      );

      final response = await _processTask(
        db: db,
        taskId: task.id,
        environment: environment,
        client: client,
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['jobs_created'], equals(1));
      expect(body['job_ids'], hasLength(1));

      final savedTask = await db.webhookTaskDao.getWebhookTask(task.id);
      expect(savedTask?.status, equals('completed'));
      expect(savedTask?.leaseUntil, isNull);

      final jobs = await db.select(db.buildJobs).get();
      expect(jobs, hasLength(1));
      expect(jobs.single.status, equals(BuildJobStatus.QUEUED));
      expect(jobs.single.owner, equals('openci-owner'));
      expect(jobs.single.repo, equals('openci-repo'));
      expect(jobs.single.workflowName, equals('Dashboard CI'));
      expect(jobs.single.workflowFileName, equals('dashboard_ci.dart'));
      expect(jobs.single.teamId, equals('team-123'));
      expect(jobs.single.commitSha, equals('commit-sha-123'));
      expect(jobs.single.commitMessage, equals('Add webhook planner tests'));
      expect(jobs.single.branch, equals('main'));
      expect(jobs.single.installationId, equals('98765'));
    });

    test(
      'rolls back BuildJobs when completing the webhook task fails',
      () async {
        final task = await _insertPushTask(db, id: 'completion-failure-task');
        final client = _githubClientWithWorkflow(
          '''
import 'package:genuine_ci/genuine_ci.dart';

Future<void> main() async {
  await GenuineCI.init(
    workflowName: 'Dashboard CI',
    ciTrigger: CiTrigger.push(branch: 'main'),
  );
}
''',
        );
        await db.customStatement('''
          CREATE TRIGGER reject_webhook_task_completion
          BEFORE UPDATE OF status ON webhook_tasks
          WHEN NEW.status = 'completed'
          BEGIN
            SELECT RAISE(ABORT, 'forced webhook task completion failure');
          END;
        ''');

        final response = await _processTask(
          db: db,
          taskId: task.id,
          environment: environment,
          client: client,
        );

        expect(response.statusCode, equals(HttpStatus.internalServerError));
        expect(await db.select(db.buildJobs).get(), isEmpty);

        final savedTask = await db.webhookTaskDao.getWebhookTask(task.id);
        expect(savedTask?.status, equals('failed'));
        expect(savedTask?.leaseUntil, isNull);
      },
    );

    test(
      'completes the task without creating a job when no workflow matches',
      () async {
        final task = await _insertPushTask(db, id: 'non-matching-task');
        final client = _githubClientWithWorkflow(
          '''
import 'package:genuine_ci/genuine_ci.dart';

Future<void> main() async {
  await GenuineCI.init(
    workflowName: 'Develop CI',
    ciTrigger: CiTrigger.push(branch: 'develop'),
  );
}
''',
        );

        final response = await _processTask(
          db: db,
          taskId: task.id,
          environment: environment,
          client: client,
        );

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['jobs_created'], equals(0));
        expect(body['job_ids'], isEmpty);
        expect(body['message'], equals('No matching workflows for event'));

        final savedTask = await db.webhookTaskDao.getWebhookTask(task.id);
        expect(savedTask?.status, equals('completed'));
        expect(savedTask?.leaseUntil, isNull);
        expect(await db.select(db.buildJobs).get(), isEmpty);
      },
    );

    test('marks the task as failed when GitHub authentication fails', () async {
      final task = await _insertPushTask(db, id: 'github-failure-task');
      final client = MockClient((request) async {
        expect(request.url.path, contains('/access_tokens'));
        return http.Response('GitHub unavailable', HttpStatus.badGateway);
      });

      final response = await _processTask(
        db: db,
        taskId: task.id,
        environment: environment,
        client: client,
      );

      expect(response.statusCode, equals(HttpStatus.internalServerError));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], equals('Internal server error'));

      final savedTask = await db.webhookTaskDao.getWebhookTask(task.id);
      expect(savedTask?.status, equals('failed'));
      expect(savedTask?.leaseUntil, isNull);
      expect(savedTask?.errorMessage, contains('GitHub unavailable'));
      expect(await db.select(db.buildJobs).get(), isEmpty);
    });
  });
}

Future<DriftWebhookTask> _insertPushTask(
  AppDatabase db, {
  required String id,
}) async {
  final now = DateTime.now().toUtc();
  final task = DriftWebhookTask(
    id: id,
    deliveryId: 'delivery-$id',
    eventType: 'push',
    payload: jsonEncode({
      'ref': 'refs/heads/main',
      'deleted': false,
      'head_commit': {
        'id': 'commit-sha-123',
        'message': 'Add webhook planner tests\n\nMore details',
      },
      'repository': {
        'name': 'openci-repo',
        'owner': {'login': 'openci-owner'},
      },
      'installation': {'id': 98765},
    }),
    status: 'processing',
    leaseUntil: now.add(const Duration(minutes: 5)),
    retryCount: 0,
    createdAt: now,
    updatedAt: now,
  );
  await db.webhookTaskDao.insertWebhookTask(task);
  return task;
}

Future<Response> _processTask({
  required AppDatabase db,
  required String taskId,
  required Map<String, String> environment,
  required http.Client client,
}) async {
  final context = TestRequestContext(
    path: '/webhooks/tasks/$taskId/process',
    method: HttpMethod.post,
  );
  context.provide<AppDatabase>(db);
  context.provide<String?>('github-webhook-processor');
  context.provide<Map<String, String>>(environment);
  context.provide<http.Client>(client);
  return route.onRequest(context.context, taskId);
}

MockClient _githubClientWithWorkflow(String workflowSource) {
  return MockClient((request) async {
    if (request.url.path.contains('/access_tokens')) {
      return http.Response(
        jsonEncode({
          'token': 'test-installation-token',
          'expires_at': '2026-09-04T00:00:00Z',
        }),
        HttpStatus.created,
      );
    }

    if (request.url.path.endsWith('/contents/genuine_ci')) {
      expect(request.url.queryParameters['ref'], equals('commit-sha-123'));
      return http.Response(
        jsonEncode([
          {
            'type': 'file',
            'name': 'dashboard_ci.dart',
            'path': 'genuine_ci/dashboard_ci.dart',
          },
        ]),
        HttpStatus.ok,
      );
    }

    if (request.url.path.endsWith(
      '/contents/genuine_ci/dashboard_ci.dart',
    )) {
      expect(request.url.queryParameters['ref'], equals('commit-sha-123'));
      return http.Response(
        jsonEncode({
          'type': 'file',
          'encoding': 'base64',
          'name': 'dashboard_ci.dart',
          'path': 'genuine_ci/dashboard_ci.dart',
          'content': base64Encode(utf8.encode(workflowSource)),
        }),
        HttpStatus.ok,
      );
    }

    return http.Response('Not Found', HttpStatus.notFound);
  });
}
