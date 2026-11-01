import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:stacked_pr_app/src/models.dart';
import 'package:stacked_pr_app/src/queue.dart';
import 'package:stacked_pr_app/src/runtime.dart';

void main() {
  test('task uses stable delivery ID, private OIDC target, and bounded deadline', () async {
    final requests = <http.Request>[];
    final queue = TaskQueue(
      client: MockClient((r) async {
        requests.add(r);
        return http.Response('{}', requests.length == 1 ? 200 : 409);
      }),
      project: 'demo-stacked-pr',
      workerUrl: Uri.parse('https://worker.example.run.app'),
      serviceAccount: 'tasks@example.iam.gserviceaccount.com',
      namespace: 'github.example.com:7',
    );
    const job = Job(
      id: 'delivery',
      event: 'pull_request',
      payload: {
        'installation': {'id': 1},
      },
    );
    expect(await queue.enqueue(job), isTrue);
    expect(await queue.enqueue(job), isFalse);
    final task = jsonObject(jsonObject(jsonDecode(requests.first.body))['task']);
    expect(jsonDecode(requests.last.body), jsonDecode(requests.first.body));
    expect(
      task['name'],
      startsWith('projects/demo-stacked-pr/locations/asia-northeast1/queues/stacked-pr/tasks/'),
    );
    expect(task['dispatchDeadline'], '600s');
    final request = jsonObject(task['httpRequest']);
    expect(jsonObject(request['oidcToken'])['audience'], 'https://worker.example.run.app');
    expect(
      jsonObject(jsonDecode(utf8.decode(base64Decode(request['body'] as String))))['id'],
      job.id,
    );
  });
  test('failed enqueue does not acknowledge accepted delivery', () async {
    final queue = TaskQueue(
      client: MockClient((_) async => http.Response('private details', 503)),
      project: 'demo-stacked-pr',
      workerUrl: Uri.parse('https://worker.example.run.app'),
      serviceAccount: 'tasks@example.iam.gserviceaccount.com',
      namespace: 'app',
    );
    await expectLater(
      queue.enqueue(const Job(id: 'delivery', event: 'push', payload: {})),
      throwsA(isA<RetryException>()),
    );
  });
  test('cutover accepts tasks now but schedules them after old tokens expire', () async {
    for (final delay in [const Duration(minutes: 65), const Duration(minutes: -1)]) {
      final notBefore = DateTime.now().toUtc().add(delay);
      Json? task;
      final queue = TaskQueue(
        client: MockClient((request) async {
          task = jsonObject(jsonObject(jsonDecode(request.body))['task']);
          return http.Response('{}', 200);
        }),
        project: 'demo-stacked-pr',
        workerUrl: Uri.parse('https://worker.example.run.app'),
        serviceAccount: 'tasks@example.iam.gserviceaccount.com',
        namespace: 'app',
        notBefore: notBefore,
      );
      expect(await queue.enqueue(const Job(id: 'delivery', event: 'push', payload: {})), isTrue);
      expect(task!['scheduleTime'], delay.isNegative ? isNull : notBefore.toIso8601String());
      queue.close();
    }
  });
  test('worker awaits completion, returns retry on failure and rejects malformed jobs', () async {
    Request request(String body) => Request('POST', Uri.parse('http://localhost/'), body: body);
    final body = jsonEncode({
      'id': 'delivery',
      'event': 'reconcile',
      'payload': <String, Object?>{},
    });
    var calls = 0;
    expect(
      (await processTask(request(body), (job) async {
        calls++;
      })).statusCode,
      200,
    );
    expect(calls, 1);
    expect(
      (await processTask(request(body), (_) async => throw StateError('secret'))).statusCode,
      503,
    );
    expect(
      (await processTask(request('{}'), (_) async {
        calls++;
      })).statusCode,
      400,
    );
    expect((await processTask(request('x' * (128 * 1024 + 1)), (_) async {})).statusCode, 413);
    expect(calls, 1);
  });
}
