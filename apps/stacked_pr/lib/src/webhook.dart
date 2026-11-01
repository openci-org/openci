import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'models.dart';
import 'store.dart';

bool validSignature(List<int> body, String? signature, String secret) {
  if (signature == null || !RegExp(r'^sha256=[a-f0-9]{64}$').hasMatch(signature)) return false;
  final expected = Hmac(sha256, utf8.encode(secret)).convert(body).bytes;
  var difference = 0;
  for (var i = 0; i < expected.length; i++) {
    difference |= expected[i] ^ int.parse(signature.substring(7 + i * 2, 9 + i * 2), radix: 16);
  }
  return difference == 0;
}

Json _object(Object? value) => value is Map ? jsonObject(value) : {};
bool relevant(String? event, Json payload) => switch (event) {
  'pull_request' => [
    'opened',
    'reopened',
    'synchronize',
    'edited',
    'closed',
    'ready_for_review',
    'converted_to_draft',
  ].contains(payload['action']),
  'push' => (payload['ref'] as String? ?? '').startsWith('refs/heads/'),
  'issue_comment' =>
    payload['action'] == 'created' &&
        _object(payload['issue'])['pull_request'] != null &&
        (_object(payload['comment'])['body'] as String?)?.trim() == '/stack sync',
  'check_run' =>
    payload['action'] == 'requested_action' &&
        _object(payload['requested_action'])['identifier'] == 'restack',
  'installation' || 'installation_repositories' => [
    'created',
    'added',
    'unsuspend',
    'deleted',
    'removed',
    'suspend',
  ].contains(payload['action']),
  _ => false,
};

class WebhookReceiver {
  WebhookReceiver(this.store, this.secret, {this.limit = 2 * 1024 * 1024});
  final Store store;
  final String secret;
  final int limit;
  Response _reply(int status, Json body) => Response.json(
    statusCode: status,
    body: body,
    headers: {HttpHeaders.cacheControlHeader: 'no-store'},
  );

  Future<Response> accept(Request request) async {
    try {
      final bytes = BytesBuilder(copy: false);
      final stopwatch = Stopwatch()..start();
      await for (final chunk in request.bytes().timeout(const Duration(seconds: 30))) {
        if (stopwatch.elapsed > const Duration(seconds: 30)) {
          throw TimeoutException('Request timed out');
        }
        if (bytes.length + chunk.length > limit) return _reply(413, {'error': 'payload_too_large'});
        bytes.add(chunk);
      }
      final body = bytes.takeBytes();
      if (!validSignature(body, request.headers['x-hub-signature-256'], secret)) {
        return _reply(401, {'error': 'invalid_signature'});
      }
      final Object? decoded;
      try {
        decoded = jsonDecode(utf8.decode(body));
      } on FormatException {
        return _reply(400, {'error': 'invalid_json'});
      }
      if (decoded is! Map<String, Object?>) return _reply(400, {'error': 'invalid_payload'});
      final event = request.headers['x-github-event'];
      if (event == 'ping') return _reply(200, {'pong': true});
      if (!relevant(event, decoded)) return _reply(200, {'ignored': true});
      final delivery = request.headers['x-github-delivery'];
      if (delivery == null || !RegExp(r'^[\w-]{1,128}$').hasMatch(delivery)) {
        return _reply(400, {'error': 'invalid_delivery'});
      }
      final installation = _object(decoded['installation'])['id'];
      if (installation is! int || installation <= 0) {
        return _reply(400, {'error': 'missing_installation'});
      }
      final inserted = store.enqueue(delivery, event!, decoded);
      return _reply(202, {'accepted': true, 'duplicate': !inserted});
    } catch (_) {
      stderr.writeln('Webhook persistence or request failed');
      return _reply(503, {'error': 'temporarily_unavailable'});
    }
  }
}
