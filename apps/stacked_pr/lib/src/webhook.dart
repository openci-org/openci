import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'models.dart';

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
  WebhookReceiver(this.enqueue, this.secret, {this.limit = 2 * 1024 * 1024});
  final Future<bool> Function(Job) enqueue;
  final String secret;
  final int limit;
  Response _reply(int status, Json body) => Response(
    status,
    body: jsonEncode(body),
    headers: {
      HttpHeaders.cacheControlHeader: 'no-store',
      HttpHeaders.contentTypeHeader: 'application/json',
    },
  );

  Future<Response> accept(Request request) async {
    if (request.method != 'POST') return Response(405, headers: {'allow': 'POST'});
    try {
      final bytes = BytesBuilder(copy: false);
      final stopwatch = Stopwatch()..start();
      await for (final chunk in request.read().timeout(const Duration(seconds: 30))) {
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
      final inserted = await enqueue(
        Job(id: delivery, event: event!, payload: compactPayload(decoded)),
      );
      return _reply(202, {'accepted': true, 'duplicate': !inserted});
    } catch (_) {
      stderr.writeln('Webhook queue or request failed');
      return _reply(503, {'error': 'temporarily_unavailable'});
    }
  }
}

// Retain only routing/authorization inputs, not PR bodies, patches or commit lists.
Json compactPayload(Json raw) => {
  'action': raw['action'],
  if (raw['ref'] != null) 'ref': raw['ref'],
  if (_object(_object(_object(raw['changes'])['base'])['ref'])['from'] case final String previous)
    'previous_base': previous,
  'installation': {'id': _object(raw['installation'])['id']},
  'repository': {
    'id': _object(raw['repository'])['id'],
    'full_name': _object(raw['repository'])['full_name'],
  },
  'sender': {'login': _object(raw['sender'])['login'], 'type': _object(raw['sender'])['type']},
  if (raw['pull_request'] != null)
    'pull_request': {'number': _object(raw['pull_request'])['number']},
  if (raw['issue'] != null)
    'issue': {
      'number': _object(raw['issue'])['number'],
      if (_object(raw['issue'])['pull_request'] != null) 'pull_request': <String, Object?>{},
    },
  if (raw['comment'] != null) 'comment': {'body': _object(raw['comment'])['body']},
  if (raw['check_run'] != null)
    'check_run': {
      'app': {'id': _object(_object(raw['check_run'])['app'])['id']},
      'external_id': _object(raw['check_run'])['external_id'],
    },
  if (raw['requested_action'] != null)
    'requested_action': {'identifier': _object(raw['requested_action'])['identifier']},
};
