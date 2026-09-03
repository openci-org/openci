import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../routes/webhook.dart' as route;

void main() {
  group('POST /webhook', () {
    const testSecret = 'super-secret-key';
    const testBody = '{"event": "push", "ref": "refs/heads/main"}';

    test(
      'responds with 405 Method Not Allowed when method is not POST',
      () async {
        final context = TestRequestContext(
          path: '/webhook',
          method: HttpMethod.get,
        );

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      },
    );

    test('responds with 401 when signature header is missing', () async {
      final context = TestRequestContext(
        path: '/webhook',
        method: HttpMethod.post,
        body: testBody,
      );

      context.provide<Map<String, String>>({
        'GITHUB_WEBHOOK_SECRET': testSecret,
      });

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], equals('Missing or invalid signature header'));
    });

    test('responds with 401 when signature header format is invalid', () async {
      final context = TestRequestContext(
        path: '/webhook',
        method: HttpMethod.post,
        body: testBody,
        headers: {
          'x-hub-signature-256': 'invalid-format-signature-value',
        },
      );

      context.provide<Map<String, String>>({
        'GITHUB_WEBHOOK_SECRET': testSecret,
      });

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], equals('Missing or invalid signature header'));
    });

    test('responds with 401 when signature does not match', () async {
      final context = TestRequestContext(
        path: '/webhook',
        method: HttpMethod.post,
        body: testBody,
        headers: {
          'x-hub-signature-256':
              'sha256=wrongsignaturevalue12345678901234567890',
        },
      );

      context.provide<Map<String, String>>({
        'GITHUB_WEBHOOK_SECRET': testSecret,
      });

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], equals('Signature mismatch'));
    });
  });

  group('constantTimeCompare', () {
    test('returns true for identical lists', () {
      expect(
        constantTimeCompare([1, 2, 3], [1, 2, 3]),
        isTrue,
      );
    });

    test('returns false for lists of different lengths', () {
      expect(
        constantTimeCompare([1, 2, 3], [1, 2]),
        isFalse,
      );
      expect(
        constantTimeCompare([1, 2], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns false for lists with different values at the beginning', () {
      expect(
        constantTimeCompare([9, 2, 3], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns false for lists with different values in the middle', () {
      expect(
        constantTimeCompare([1, 9, 3], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns false for lists with different values at the end', () {
      expect(
        constantTimeCompare([1, 2, 9], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns true for empty lists', () {
      expect(
        constantTimeCompare([], []),
        isTrue,
      );
    });
  });

  group('webhook queue persistence', () {
    const testSecret = 'super-secret-key';
    late AppDatabase db;

    String computeSignature(String body) {
      final hmacSha256 = Hmac(sha256, utf8.encode(testSecret));
      return 'sha256=${hmacSha256.convert(utf8.encode(body))}';
    }

    Future<Response> queuePushWebhook({
      required String body,
      required String deliveryId,
    }) {
      final context = TestRequestContext(
        path: '/webhook',
        method: HttpMethod.post,
        body: body,
        headers: {
          'x-hub-signature-256': computeSignature(body),
          'x-github-event': 'push',
          'x-github-delivery': deliveryId,
        },
      );
      context.provide<Map<String, String>>({
        'GITHUB_WEBHOOK_SECRET': testSecret,
      });
      context.provide<AppDatabase>(db);
      return route.onRequest(context.context);
    }

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    test('queues a valid webhook delivery', () async {
      const body = '{"ref":"refs/heads/main"}';

      final response = await queuePushWebhook(
        body: body,
        deliveryId: 'new-delivery',
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      final responseBody = await response.json() as Map<String, dynamic>;
      expect(responseBody['success'], isTrue);
      expect(responseBody['message'], equals('Webhook received and queued.'));

      final tasks = await db.select(db.webhookTasks).get();
      expect(tasks, hasLength(1));
      expect(tasks.single.deliveryId, equals('new-delivery'));
      expect(tasks.single.eventType, equals('push'));
      expect(tasks.single.payload, equals(body));
      expect(tasks.single.status, equals('pending'));
    });

    test('does not report a queue insertion failure as a duplicate', () async {
      await db.customStatement('''
        CREATE TRIGGER reject_webhook_task_insert
        BEFORE INSERT ON webhook_tasks
        BEGIN
          SELECT RAISE(ABORT, 'forced webhook task insertion failure');
        END;
      ''');

      final response = await queuePushWebhook(
        body: '{"ref":"refs/heads/main"}',
        deliveryId: 'failed-delivery',
      );

      expect(response.statusCode, equals(HttpStatus.internalServerError));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], equals('Internal server error'));
      expect(await db.select(db.webhookTasks).get(), isEmpty);
    });

    test('treats only a duplicate delivery as already processed', () async {
      final now = DateTime.now().toUtc();
      await db.webhookTaskDao.insertWebhookTask(
        DriftWebhookTask(
          id: 'existing-task',
          deliveryId: 'duplicate-delivery',
          eventType: 'push',
          payload: '{"ref":"refs/heads/main"}',
          status: 'pending',
          retryCount: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final response = await queuePushWebhook(
        body: '{"ref":"refs/heads/main"}',
        deliveryId: 'duplicate-delivery',
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['message'], contains('already processed'));
      expect(await db.select(db.webhookTasks).get(), hasLength(1));
    });
  });
}
