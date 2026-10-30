import 'dart:async';
import 'dart:convert';

import 'package:openci_dart_functions/process_webhook_task.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Request request(String body, {String method = 'POST'}) =>
    Request(method, Uri.parse('http://localhost/'), body: body);

void main() {
  test(
    'dispatches one durable task ID and acknowledges terminal results',
    () async {
      for (final result in ['created', 'duplicate', 'failed']) {
        final response = await processWebhookTask(
          request('{"taskId":"task-1"}'),
          (id) async {
            expect(id, 'task-1');
            return result;
          },
        );
        expect(response.statusCode, 200);
        expect(jsonDecode(await response.readAsString()), {'result': result});
      }
    },
  );

  test(
    'rejects raw payloads, invalid IDs, malformed JSON and methods',
    () async {
      var calls = 0;
      Future<String> process(String id) async {
        calls++;
        return 'created';
      }

      for (final body in [
        '{}',
        '{',
        '[]',
        '{"taskId":""}',
        '{"taskId":1}',
        '{"taskId":"task","payload":"private"}',
      ]) {
        expect(
          (await processWebhookTask(request(body), process)).statusCode,
          400,
        );
      }
      expect(
        (await processWebhookTask(
          request('', method: 'GET'),
          process,
        )).statusCode,
        405,
      );
      expect(calls, 0);
    },
  );

  test('limits streamed input before executing a task', () async {
    final response = await processWebhookTask(
      Request(
        'POST',
        Uri.parse('http://localhost/'),
        body: Stream.fromIterable([
          List.filled(4096, 32),
          [32],
        ]),
      ),
      (_) async => fail('Must not dispatch'),
    );
    expect(response.statusCode, 413);
  });

  test(
    'transient failures return 503 without logging private exception data',
    () async {
      final logs = <String>[];
      final response = await runZoned(
        () => processWebhookTask(
          request('{"taskId":"task"}'),
          (_) async => throw StateError('secret-token-and-payload'),
        ),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => logs.add(line),
        ),
      );
      expect(response.statusCode, 503);
      expect(await response.readAsString(), '{"error":"planning_unavailable"}');
      expect(logs.single, isNot(contains('secret-token-and-payload')));
    },
  );
}
