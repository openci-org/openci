import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:test/test.dart';

import '../../../routes/devices/mobile-config.dart' as route;

void main() {
  setUp(() {
    route.allowedRedirectOrigins = {'https://dashboard.openci.org'};
  });

  group('GET /devices/mobile-config', () {
    test('returns 400 Bad Request when userId or teamId is missing', () async {
      final context = TestRequestContext(
        path: '/devices/mobile-config',
        method: HttpMethod.get,
      );

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], contains('Missing required parameters'));
    });

    test(
      'returns 200 and mobileconfig XML with callback URL pointing to redirectOrigin/register-device',
      () async {
        final context = TestRequestContext(
          path:
              '/devices/mobile-config?userId=user-123&teamId=team-123&redirectOrigin=https://dashboard.openci.org',
          method: HttpMethod.get,
        );

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));
        expect(
          response.headers['Content-Type'],
          equals('application/x-apple-aspen-config; charset=utf-8'),
        );
        expect(
          response.headers['Content-Disposition'],
          equals('attachment; filename="openci-udid.mobileconfig"'),
        );

        final xml = await response.body();
        expect(xml, contains('<key>URL</key>'));
        expect(
          xml,
          contains(
            'https://dashboard.openci.org/register-device'
            '?userId=user-123'
            '&teamId=team-123'
            '&redirectOrigin=https%3A%2F%2Fdashboard.openci.org',
          ),
        );
      },
    );

    test('returns 400 Bad Request when redirectOrigin is missing', () async {
      final context = TestRequestContext(
        path: '/devices/mobile-config?userId=user-123&teamId=team-123',
        method: HttpMethod.get,
      );

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], contains('Invalid redirectOrigin'));
    });

    test('returns 400 Bad Request when redirectOrigin is not allowed', () async {
      final context = TestRequestContext(
        path:
            '/devices/mobile-config?userId=user-123&teamId=team-123&redirectOrigin=https://malicious.com',
        method: HttpMethod.get,
      );

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], contains('Invalid redirectOrigin'));
    });
  });

  group('Other methods', () {
    test('returns 405 Method Not Allowed for POST', () async {
      final context = TestRequestContext(
        path: '/devices/mobile-config',
        method: HttpMethod.post,
        body: 'dummy',
      );

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('returns 405 Method Not Allowed for DELETE', () async {
      final context = TestRequestContext(
        path: '/devices/mobile-config',
        method: HttpMethod.delete,
      );

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });
}
