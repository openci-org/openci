import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:postgres/postgres.dart' as pg;
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

  final secret = env['GITHUB_WEBHOOK_SECRET']!;

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

  final now = DateTime.now().toUtc();
  final taskId = const Uuid().v4();
  final task = DriftWebhookTask(
    id: taskId,
    deliveryId: deliveryId,
    eventType: eventType,
    payload: rawBody,
    status: 'pending',
    retryCount: 0,
    createdAt: now,
    updatedAt: now,
  );

  try {
    await db.webhookTaskDao.insertWebhookTask(task);
  } catch (error, stackTrace) {
    if (_isUniqueConstraintViolation(error)) {
      return Response.json(
        body: {
          'success': true,
          'message': 'Webhook delivery already processed',
        },
      );
    }

    return handleRouteException(
      error,
      stackTrace,
      logMessage: 'Failed to queue webhook delivery $deliveryId',
    );
  }

  return Response.json(
    body: {
      'success': true,
      'message': 'Webhook received and queued.',
    },
  );
}

bool _isUniqueConstraintViolation(Object error) {
  if (error is pg.UniqueViolationException) {
    return true;
  }
  if (error is pg.ServerException && error.code == '23505') {
    return true;
  }

  return error.runtimeType.toString() == 'SqliteException' &&
      error.toString().contains('UNIQUE constraint failed');
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
