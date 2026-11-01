import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:stacked_pr_app/src/models.dart';
import 'package:stacked_pr_app/src/store.dart';
import 'package:stacked_pr_app/src/webhook.dart';
import '../../routes/webhooks.dart' as webhooks;
import '../../routes/healthz.dart' as healthz;
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
  test('HTTP persists signed deliveries before ack, deduplicates and bounds input', () async {
    final store = Store(':memory:');
    final router = Router()
      ..all('/webhooks', webhooks.onRequest)
      ..all('/healthz', healthz.onRequest);
    final server = await serve(
      router.call.use(provider<WebhookReceiver>((_) => WebhookReceiver(store, secret, limit: 512))),
      '127.0.0.1',
      0,
    );
    final client = http.Client();
    addTearDown(() async {
      client.close();
      await server.close(force: true);
      store.close();
    });
    final origin = 'http://127.0.0.1:${server.port}';
    Future<http.Response> send(String body, {bool signed = true, String id = 'delivery'}) =>
        client.post(
          Uri.parse('$origin/webhooks'),
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
    });
    expect((await send(body, signed: false)).statusCode, 401);
    expect(store.next(), isNull);
    expect((await send(body)).statusCode, 202);
    expect(jsonObject(jsonDecode((await send(body)).body))['duplicate'], isTrue);
    expect((await send('{')).statusCode, 400);
    expect((await send('[]')).statusCode, 400);
    expect((await send('x' * 513)).statusCode, 413);
    expect((await send(body, id: '!bad')).statusCode, 400);
    expect((await send('{"action":"opened"}')).statusCode, 400);
    expect((await client.get(Uri.parse('$origin/healthz'))).statusCode, 200);
    expect((await client.get(Uri.parse('$origin/webhooks'))).statusCode, 405);
    expect((await client.post(Uri.parse('$origin/healthz'))).statusCode, 405);
    expect(store.next()!.id, 'delivery');
  });
}
