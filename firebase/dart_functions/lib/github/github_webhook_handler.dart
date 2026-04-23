import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../secret_manager.dart';
import '../util/logger.dart';
import 'webhook_event.dart';
import 'webhook_router.dart';
import 'webhook_verifier.dart';

Future<Response> handleGitHubWebhook(Request request) async {
  try {
    final payload = await request.readAsString();

    final secret = await accessSecret('GITHUB_WEBHOOK_SECRET');
    final error = await verifyWebhook(
      payload: payload,
      headers: request.headers,
      secret: secret,
    );
    if (error != null) return error;

    final eventType = request.headers['x-github-event'];
    if (eventType == null) {
      return Response(400, body: 'Missing x-github-event header');
    }
    final body = jsonDecode(payload) as Map<String, dynamic>;
    final event = WebhookEvent.fromRequest(event: eventType, body: body);

    await routeWebhookEvent(event);

    return Response.ok(
      jsonEncode({'status': 'ok'}),
      headers: {'content-type': 'application/json'},
    );
  } catch (e, stackTrace) {
    await logError('Webhook processing failed', {
      'stackTrace': stackTrace.toString(),
    }, e);
    return Response.internalServerError(body: 'Error');
  }
}
