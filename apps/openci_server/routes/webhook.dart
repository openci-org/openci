import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/webhook_task_worker.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:uuid/uuid.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  Map<String, String> env;
  try {
    env = context.read<Map<String, String>>();
  } catch (_) {
    env = Platform.environment;
  }

  final secret = env['GITHUB_WEBHOOK_SECRET'];
  if (secret == null || secret.isEmpty) {
    stderr.writeln('Warning: GITHUB_WEBHOOK_SECRET is not configured.');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Server configuration error'},
    );
  }

  final signatureHeader = context.request.headers['x-hub-signature-256'];
  if (signatureHeader == null || !signatureHeader.startsWith('sha256=')) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'success': false, 'error': 'Missing or invalid signature header'},
    );
  }

  final rawBody = await context.request.body();
  if (!verifyWebhookSignature(
    rawBody: rawBody,
    signatureHeader: signatureHeader,
    secret: secret,
  )) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'success': false, 'error': 'Signature mismatch'},
    );
  }

  final deliveryId = context.request.headers['x-github-delivery'];
  if (deliveryId == null || deliveryId.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'success': false, 'error': 'Missing x-github-delivery header'},
    );
  }

  final db = context.read<AppDatabase>();
  final exists = await (db.select(
    db.processedWebhooks,
  )..where((t) => t.deliveryId.equals(deliveryId))).getSingleOrNull();
  if (exists != null) {
    return Response.json(
      body: {
        'success': true,
        'message': 'Webhook delivery already processed',
      },
    );
  }

  final eventType = context.request.headers['x-github-event'] ?? '';
  if (eventType != 'pull_request' && eventType != 'push') {
    return Response.json(
      body: {
        'success': true,
        'message': 'Ignored event type: $eventType',
      },
    );
  }

  // PR action filtering
  if (eventType == 'pull_request') {
    try {
      final payload = jsonDecode(rawBody) as Map<String, dynamic>;
      final action = payload['action'] as String?;
      if (action != 'opened' &&
          action != 'synchronize' &&
          action != 'reopened') {
        return Response.json(
          body: {
            'success': true,
            'message': 'Ignored pull_request action: $action',
          },
        );
      }
    } catch (_) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Invalid JSON body'},
      );
    }
  }

  // 1. Record in processed webhooks table (idempotency check)
  await db
      .into(db.processedWebhooks)
      .insert(
        ProcessedWebhooksCompanion.insert(
          deliveryId: deliveryId,
          processedAt: DateTime.now().toUtc(),
        ),
      );

  // 2. Insert into the queue table
  final taskId = const Uuid().v4();
  final task = DriftWebhookTask(
    id: taskId,
    deliveryId: deliveryId,
    eventType: eventType,
    payload: rawBody,
    status: 'pending',
    retryCount: 0,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );

  try {
    await db.webhookTaskDao.insertWebhookTask(task);
  } catch (e) {
    // Unique constraint violation (duplicate webhook task)
    return Response.json(
      body: {
        'success': true,
        'message': 'Webhook delivery already processed (via task check)',
      },
    );
  }

  // 3. Ping the background worker stream
  webhookTaskController.add(null);

  return Response.json(
    body: {
      'success': true,
      'message': 'Webhook received and queued.',
    },
  );
}

bool verifyWebhookSignature({
  required String rawBody,
  required String signatureHeader,
  required String secret,
}) {
  if (!signatureHeader.startsWith('sha256=')) {
    return false;
  }
  final expectedSignature = signatureHeader.substring(7);
  final rawBodyBytes = utf8.encode(rawBody);

  final key = utf8.encode(secret);
  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(rawBodyBytes);
  final computedSignature = digest.toString();

  final computedSignatureBytes = utf8.encode(computedSignature);
  final expectedSignatureBytes = utf8.encode(expectedSignature);

  return constantTimeCompare(computedSignatureBytes, expectedSignatureBytes);
}
