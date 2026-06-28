import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../../routes/devices/mobile-config.dart' as route;

void main() {
  late AppDatabase db;

  setUp(() async {
    route.allowedRedirectOrigins = {'https://dashboard.openci.org'};
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
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
            'devices/mobile-config'
            '?userId=user-123'
            '&amp;teamId=team-123'
            '&amp;redirectOrigin=https%3A%2F%2Fdashboard.openci.org',
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

    test('returns 400 Bad Request when server port is invalid', () async {
      final context = MockRequestContext();
      final request = MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.uri).thenReturn(
        Uri.parse(
          'http://localhost:0/devices/mobile-config?userId=user-123&teamId=team-123&redirectOrigin=https://dashboard.openci.org',
        ),
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], contains('Invalid server port'));
    });
  });

  group('Other methods', () {
    test('returns 405 Method Not Allowed for DELETE', () async {
      final context = TestRequestContext(
        path: '/devices/mobile-config',
        method: HttpMethod.delete,
      );

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });

  group('POST /devices/mobile-config', () {
    test('successfully extracts UDID, stores in DB and redirects', () async {
      final context = TestRequestContext(
        path:
            '/devices/mobile-config?userId=user-123&teamId=team-123&redirectOrigin=https://dashboard.openci.org',
        method: HttpMethod.post,
        body: '''
<?xml version="1.0" encoding="UTF-8"?>
<plist>
<dict>
  <key>UDID</key>
  <string>test-udid-456-longer-than-25-chars</string>
  <key>PRODUCT</key>
  <string>iPhone14,2</string>
  <key>VERSION</key>
  <string>16.5</string>
</dict>
</plist>
''',
      );
      context.provide<AppDatabase>(db);

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.seeOther));
      expect(
        response.headers['Location'],
        equals(
          'https://dashboard.openci.org/?enrolled=true&udid=test-udid-456-longer-than-25-chars#/distributions',
        ),
      );

      final device = await db.deviceDao.findDevice(
        userId: 'user-123',
        teamId: 'team-123',
        udid: 'test-udid-456-longer-than-25-chars',
      );
      expect(device, isNotNull);
      expect(device!.deviceProduct, equals('iPhone14,2'));
      expect(device.deviceOsVersion, equals('16.5'));
    });

    test(
      'successfully updates an existing device on conflict (upsert)',
      () async {
        await db.deviceDao.createDevice(
          userId: 'user-123',
          teamId: 'team-123',
          udid: 'test-udid-456-longer-than-25-chars',
          deviceProduct: 'iPhone14,2',
          deviceOsVersion: '16.5',
        );

        final context = TestRequestContext(
          path:
              '/devices/mobile-config?userId=user-123&teamId=team-123&redirectOrigin=https://dashboard.openci.org',
          method: HttpMethod.post,
          body: '''
<?xml version="1.0" encoding="UTF-8"?>
<plist>
<dict>
  <key>UDID</key>
  <string>test-udid-456-longer-than-25-chars</string>
  <key>PRODUCT</key>
  <string>iPhone15,3</string>
  <key>VERSION</key>
  <string>17.0</string>
</dict>
</plist>
''',
        );
        context.provide<AppDatabase>(db);

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.seeOther));

        final device = await db.deviceDao.findDevice(
          userId: 'user-123',
          teamId: 'team-123',
          udid: 'test-udid-456-longer-than-25-chars',
        );
        expect(device, isNotNull);
        expect(device!.deviceProduct, equals('iPhone15,3'));
        expect(device.deviceOsVersion, equals('17.0'));
      },
    );

    test(
      'returns 400 Bad Request when userId or teamId query parameter is missing',
      () async {
        final context = TestRequestContext(
          path: '/devices/mobile-config?userId=user-123',
          method: HttpMethod.post,
          body:
              '<key>UDID</key><string>test-udid-456-longer-than-25-chars</string>',
        );
        context.provide<AppDatabase>(db);

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Missing required parameters'));
      },
    );

    test('returns 400 Bad Request when redirectOrigin is not allowed', () async {
      final context = TestRequestContext(
        path:
            '/devices/mobile-config?userId=user-123&teamId=team-123&redirectOrigin=https://malicious.com',
        method: HttpMethod.post,
        body:
            '<key>UDID</key><string>test-udid-456-longer-than-25-chars</string>',
      );
      context.provide<AppDatabase>(db);

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], contains('Invalid redirectOrigin'));
    });

    test('returns 400 Bad Request when UDID cannot be extracted', () async {
      final context = TestRequestContext(
        path:
            '/devices/mobile-config?userId=user-123&teamId=team-123&redirectOrigin=https://dashboard.openci.org',
        method: HttpMethod.post,
        body: '<key>PRODUCT</key><string>iPhone</string>',
      );
      context.provide<AppDatabase>(db);

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.badRequest));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], contains('Could not extract UDID'));
    });
  });
}

class MockRequestContext extends Mock implements RequestContext {}

class MockRequest extends Mock implements Request {}
