import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:stacked_pr_app/src/models.dart';
import 'package:stacked_pr_app/src/webhook.dart';
import '../support/fixtures.dart';

String signature(String body) =>
    'sha256=${Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(body))}';
void main() {
  test('signature authenticates raw UTF-8 and rejects malformed input', () {
    const body = '{"message":"こんにちは"}';
    expect(validSignature(utf8.encode(body), signature(body), secret), isTrue);
    expect(validSignature(utf8.encode('{}'), signature(body), secret), isFalse);
    for (final invalid in [null, '', 'sha256=ff', 'sha1=abc']) {
      expect(validSignature(utf8.encode(body), invalid, secret), isFalse);
    }
  });
  test('unrelated events cannot cause bot loops', () {
    expect(relevant('check_run', {'action': 'completed'}), isFalse);
    expect(relevant('push', {'ref': 'refs/tags/release'}), isFalse);
    expect(
      relevant('issue_comment', {
        'action': 'created',
        'comment': {'body': '/stack sync'},
      }),
      isFalse,
    );
    expect(relevant('pull_request', {'action': 'synchronize'}), isTrue);
  });
  test('compaction keeps the old base needed to refresh a detached stack', () {
    final payload = compactPayload({
      'changes': {
        'body': {'from': 'private body'},
        'base': {
          'ref': {'from': 'parent'},
          'sha': {'from': 'a' * 40},
        },
      },
      'pull_request': {'number': 3, 'body': 'private body'},
    });
    expect(payload['previous_base'], 'parent');
    expect(payload['pull_request'], {'number': 3});
    expect(jsonEncode(payload), isNot(contains('private body')));
  });
  test('only a newly created sync command on a PR is relevant', () {
    final payload = <String, Object?>{
      'action': 'created',
      'issue': {'pull_request': <String, Object?>{}},
    };
    for (final command in ['/stack sync', '  /stack sync\n']) {
      expect(
        relevant('issue_comment', {
          ...payload,
          'comment': {'body': command},
        }),
        isTrue,
      );
    }
    for (final command in ['/stack rebase', '/stack retry', '/stack sync extra', 'hello']) {
      expect(
        relevant('issue_comment', {
          ...payload,
          'comment': {'body': command},
        }),
        isFalse,
      );
    }
    expect(
      relevant('issue_comment', {
        ...payload,
        'action': 'edited',
        'comment': {'body': '/stack sync'},
      }),
      isFalse,
    );
  });
  test('signed deliveries await enqueue; duplicate and failure responses are safe', () async {
    final jobs = <String, Job>{};
    var fail = false;
    final receiver = WebhookReceiver(
      (job) async {
        if (fail) throw StateError('queue unavailable');
        final fresh = !jobs.containsKey(job.id);
        jobs[job.id] = job;
        return fresh;
      },
      secret,
      limit: 512,
    );
    final server = await shelf_io.serve(receiver.accept, '127.0.0.1', 0);
    final client = http.Client();
    addTearDown(() async {
      client.close();
      await server.close(force: true);
    });
    final url = Uri.parse('http://127.0.0.1:${server.port}');
    Future<http.Response> send(String body, {bool signed = true, String id = 'delivery'}) =>
        client.post(
          url,
          body: body,
          headers: {
            'x-github-event': 'pull_request',
            'x-github-delivery': id,
            if (signed) 'x-hub-signature-256': signature(body),
          },
        );
    final body = jsonEncode({
      'action': 'opened',
      'installation': {'id': 1},
      'pull_request': {'number': 2, 'body': 'private text'},
    });
    expect((await send(body, signed: false)).statusCode, 401);
    expect(jobs, isEmpty);
    expect((await send(body)).statusCode, 202);
    expect(jsonDecode((await send(body)).body)['duplicate'], isTrue);
    expect(jobs['delivery']!.payload['pull_request'], {'number': 2});
    expect((await send('{')).statusCode, 400);
    expect((await send('[]')).statusCode, 400);
    expect((await send('x' * 513)).statusCode, 413);
    expect((await send(body, id: '!bad')).statusCode, 400);
    expect((await send('{"action":"opened"}')).statusCode, 400);
    expect((await client.get(url)).statusCode, 405);
    fail = true;
    expect((await send(body, id: 'retry')).statusCode, 503);
    expect(jobs.containsKey('retry'), isFalse);
  });
}
