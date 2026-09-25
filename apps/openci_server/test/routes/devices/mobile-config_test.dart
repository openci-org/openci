import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../../routes/devices/mobile-config.dart' as route;

void main() {
  const enrollmentPath =
      '/devices/mobile-config?userId=user-123&teamId=team-123'
      '&redirectOrigin=https://dashboard.openci.org';
  const udid = 'test-udid-456-longer-than-25-chars';
  const enrollmentPayload =
      '''
<plist>
<dict>
  <key>UDID</key>
  <string>$udid</string>
  <key>PRODUCT</key>
  <string>iPhone15,3</string>
  <key>VERSION</key>
  <string>17.0</string>
</dict>
</plist>
''';

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('GET /devices/mobile-config', () {
    test('returns 410 for an anonymous download request', () {
      final context = TestRequestContext(
        path: enrollmentPath,
        method: HttpMethod.get,
      );
      context.provide<String?>(null);

      final response = route.onRequest(context.context);

      expect(response.statusCode, HttpStatus.gone);
    });

    test('returns 410 for an authenticated download request', () {
      final context = TestRequestContext(
        path: enrollmentPath,
        method: HttpMethod.get,
      );
      context.provide<String?>('user-123');

      final response = route.onRequest(context.context);

      expect(response.statusCode, HttpStatus.gone);
    });
  });

  group('POST /devices/mobile-config', () {
    test('returns 410 for a valid enrollment payload', () {
      final context = TestRequestContext(
        path: enrollmentPath,
        method: HttpMethod.post,
        body: enrollmentPayload,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);

      final response = route.onRequest(context.context);

      expect(response.statusCode, HttpStatus.gone);
    });

    test('does not create a device for an anonymous callback', () async {
      final context = TestRequestContext(
        path: enrollmentPath,
        method: HttpMethod.post,
        body: enrollmentPayload,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);

      route.onRequest(context.context);

      expect(await db.select(db.userDevices).get(), isEmpty);
    });

    test('does not create a device with an invalid token', () async {
      final context = TestRequestContext(
        path: enrollmentPath,
        method: HttpMethod.post,
        headers: {'Authorization': 'Bearer invalid-token'},
        body: enrollmentPayload,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);

      route.onRequest(context.context);

      expect(await db.select(db.userDevices).get(), isEmpty);
    });

    test('does not create a device for another user', () async {
      final context = TestRequestContext(
        path: enrollmentPath,
        method: HttpMethod.post,
        body: enrollmentPayload,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('other-user');

      route.onRequest(context.context);

      expect(await db.select(db.userDevices).get(), isEmpty);
    });

    test('does not update an existing device for its owner', () async {
      final original = await db.deviceDao.upsertDevice(
        userId: 'user-123',
        teamId: 'team-123',
        udid: udid,
        deviceProduct: 'iPhone14,2',
        deviceOsVersion: '16.5',
      );
      final context = TestRequestContext(
        path: enrollmentPath,
        method: HttpMethod.post,
        body: enrollmentPayload,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('user-123');

      route.onRequest(context.context);

      final device = await db.deviceDao.findDevice(
        userId: 'user-123',
        teamId: 'team-123',
        udid: udid,
      );
      expect(device?.toJson(), original.toJson());
    });
  });

  test('returns 405 for unsupported methods', () {
    final context = TestRequestContext(
      path: '/devices/mobile-config',
      method: HttpMethod.delete,
    );

    final response = route.onRequest(context.context);

    expect(response.statusCode, HttpStatus.methodNotAllowed);
  });
}
