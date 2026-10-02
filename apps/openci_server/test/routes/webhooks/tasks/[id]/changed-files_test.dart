import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../../routes/webhooks/_middleware.dart' as webhooks;
import '../../../../../routes/webhooks/tasks/[id]/changed-files.dart' as route;
import '../../../../helpers/github_app_test_key.dart';

const _base = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _head = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  late AppDatabase db;
  late Directory directory;
  late Map<String, String> environment;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    directory = await Directory.systemTemp.createTemp('changed-files-route-');
    final key = await File(
      '${directory.path}/key.pem',
    ).writeAsString(testRsaPrivateKey);
    environment = {
      'GITHUB_API_BASE_URL': 'https://api.github.test',
      'GITHUB_APP_ID': '42',
      'GITHUB_PRIVATE_KEY_PATH': key.path,
    };
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<Response> request({
    HttpMethod method = HttpMethod.get,
    String? token = 'test-internal-key',
    bool provideDatabase = true,
  }) async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode(
          request.method == 'POST'
              ? {'token': 'installation-token'}
              : {
                  'base_commit': {'sha': _base},
                  'merge_base_commit': {'sha': _base},
                  'status': 'ahead',
                  'commits': [
                    {'sha': _head},
                  ],
                  'files': [
                    {'filename': 'lib/main.dart', 'status': 'modified'},
                  ],
                },
        ),
        request.method == 'POST' ? 201 : 200,
      ),
    );
    addTearDown(client.close);
    final context = TestRequestContext(
      path: '/webhooks/tasks/task-1/changed-files',
      method: method,
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (provideDatabase) context.provide<AppDatabase>(db);
    context.provide<http.Client>(client);
    context.provide<Map<String, String>>(environment);
    context.provide<String?>('user-1');
    context.provide<InternalApiKeyValidator>(
      const InternalApiKeyValidator.forTesting(
        environment: {'INTERNAL_API_KEY': 'test-internal-key'},
      ),
    );
    return webhooks.middleware((context) => route.onRequest(context, 'task-1'))(
      context.context,
    );
  }

  Future<void> insertTask({String? payload}) async {
    final now = DateTime.now().toUtc();
    await db.webhookTaskDao.insertWebhookTask(
      DriftWebhookTask(
        id: 'task-1',
        deliveryId: 'delivery-1',
        eventType: 'push',
        payload:
            payload ??
            jsonEncode({
              'repository': {
                'owner': {'login': 'openci-org'},
                'name': 'openci',
              },
              'installation': {'id': 42},
              'before': _base,
              'after': _head,
              'created': false,
              'deleted': false,
              'forced': false,
            }),
        status: 'processing',
        retryCount: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('GET /webhooks/tasks/[id]/changed-files', () {
    for (final token in [null, '', 'wrong-key', 'firebase-token']) {
      test('rejects "$token" before accessing the database', () async {
        final response = await request(token: token, provideDatabase: false);
        expect(response.statusCode, HttpStatus.unauthorized);
      });
    }

    test('rejects methods other than GET', () async {
      final response = await request(method: HttpMethod.post);
      expect(response.statusCode, HttpStatus.methodNotAllowed);
    });

    test('returns 404 for a missing task', () async {
      final response = await request();
      expect(response.statusCode, HttpStatus.notFound);
    });

    test(
      'returns the stored webhook diff without changing task state',
      () async {
        await insertTask();
        final before = await db.webhookTaskDao.getWebhookTask('task-1');
        final response = await request();
        expect(response.statusCode, HttpStatus.ok);
        final result = ChangedFilesResult.fromJson(
          await response.json() as Map<String, dynamic>,
        );
        expect(result.isComplete, isTrue);
        expect(result.paths, ['lib/main.dart']);
        expect(result.baseSha, _base);
        expect(result.headSha, _head);
        expect(await db.webhookTaskDao.getWebhookTask('task-1'), before);
      },
    );

    test('malformed stored payload returns an indeterminate result', () async {
      await insertTask(payload: 'not-json');
      final response = await request();
      expect(response.statusCode, HttpStatus.ok);
      final result = ChangedFilesResult.fromJson(
        await response.json() as Map<String, dynamic>,
      );
      expect(result.isComplete, isFalse);
      expect(result.paths, isEmpty);
      expect(result.reason, isNotEmpty);
    });
  });
}
