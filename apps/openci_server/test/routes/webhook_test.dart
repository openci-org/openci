import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:test/test.dart';

import '../../routes/webhook.dart' as route;

void main() {
  group('POST /webhook', () {
    const testSecret = 'super-secret-key';
    const testBody = '{"event": "push", "ref": "refs/heads/main"}';

    String computeSignature(String body, String secret) {
      final key = utf8.encode(secret);
      final hmacSha256 = Hmac(sha256, key);
      final digest = hmacSha256.convert(utf8.encode(body));
      return 'sha256=$digest';
    }

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

    test(
      'responds with 500 when GITHUB_WEBHOOK_SECRET is not configured',
      () async {
        final context = TestRequestContext(
          path: '/webhook',
          method: HttpMethod.post,
          body: testBody,
        );

        context.provide<Map<String, String>>({});

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.internalServerError));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Server configuration error'));
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

    test('responds with 200 OK and verifies signature when valid', () async {
      final signature = computeSignature(testBody, testSecret);
      final context = TestRequestContext(
        path: '/webhook',
        method: HttpMethod.post,
        body: testBody,
        headers: {
          'x-hub-signature-256': signature,
        },
      );

      context.provide<Map<String, String>>({
        'GITHUB_WEBHOOK_SECRET': testSecret,
      });

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['message'], equals('Signature verified'));
    });
  });

  group('constantTimeCompare', () {
    test('returns true for identical lists', () {
      expect(
        route.constantTimeCompare([1, 2, 3], [1, 2, 3]),
        isTrue,
      );
    });

    test('returns false for lists of different lengths', () {
      expect(
        route.constantTimeCompare([1, 2, 3], [1, 2]),
        isFalse,
      );
      expect(
        route.constantTimeCompare([1, 2], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns false for lists with different values at the beginning', () {
      expect(
        route.constantTimeCompare([9, 2, 3], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns false for lists with different values in the middle', () {
      expect(
        route.constantTimeCompare([1, 9, 3], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns false for lists with different values at the end', () {
      expect(
        route.constantTimeCompare([1, 2, 9], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns true for empty lists', () {
      expect(
        route.constantTimeCompare([], []),
        isTrue,
      );
    });
  });
}
