import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/device_table.dart';
import 'package:test/test.dart';

import '../../../routes/devices/register.dart' as route;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    await db
        .into(db.teams)
        .insert(
          DriftTeam(
            id: 'team-123',
            name: 'Test Team',
            installationIds: const [],
            aiEnabled: false,
            runNumber: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('POST /devices/register (integration with memory DB)', () {
    test(
      'responds with 401 Unauthorized when unauthorized (uid is null)',
      () async {
        final context = TestRequestContext(
          path: '/devices/register',
          method: HttpMethod.post,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.unauthorized));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Authentication required'));
      },
    );

    test(
      'responds with 400 Bad Request when parameters are missing or empty',
      () async {
        final context = TestRequestContext(
          path: '/devices/register',
          method: HttpMethod.post,
          body: '{"teamId": "", "udid": "00008101-000A12345678901E"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(
          body['error'],
          contains('Missing or empty required parameters'),
        );
      },
    );

    test(
      'responds with 400 Bad Request when JSON is malformed',
      () async {
        final context = TestRequestContext(
          path: '/devices/register',
          method: HttpMethod.post,
          body: '{"teamId": "team-123", ',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Malformed JSON body'));
      },
    );

    test(
      'responds with 400 Bad Request when request body is not a JSON object',
      () async {
        final context = TestRequestContext(
          path: '/devices/register',
          method: HttpMethod.post,
          body: '["not", "an", "object"]',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Request body must be a JSON object'));
      },
    );

    test(
      'responds with 200 and registers a new device successfully',
      () async {
        final context = TestRequestContext(
          path: '/devices/register',
          method: HttpMethod.post,
          body:
              '{"teamId": "team-123", "udid": "00008101-000A12345678901E", "deviceProduct": "iPhone 15 Pro", "deviceOsVersion": "17.4"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['id'], isNotEmpty);
        expect(body['userId'], equals('user-123'));
        expect(body['teamId'], equals('team-123'));
        expect(body['udid'], equals('00008101-000A12345678901E'));
        expect(body['deviceProduct'], equals('iPhone 15 Pro'));
        expect(body['deviceOsVersion'], equals('17.4'));

        // DBに存在することを確認
        final found = await db.deviceDao.findDevice(
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
        );
        expect(found, isNotNull);
        expect(found!.id, equals(body['id']));
      },
    );

    test(
      'responds with 200 and updates the existing device when it already exists',
      () async {
        final now = DateTime.now().toUtc();
        final existingDevice = DriftUserDevice(
          id: 'existing-device-id',
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
          deviceProduct: 'iPhone 14',
          deviceOsVersion: '16.5',
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        );
        await db.into(db.userDevices).insert(existingDevice);

        final context = TestRequestContext(
          path: '/devices/register',
          method: HttpMethod.post,
          body:
              '{"teamId": "team-123", "udid": "00008101-000A12345678901E", "deviceProduct": "iPhone 15 Pro", "deviceOsVersion": "17.4"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['id'], equals('existing-device-id'));
        expect(body['deviceProduct'], equals('iPhone 15 Pro'));
        expect(body['deviceOsVersion'], equals('17.4'));

        final found = await db.deviceDao.findDevice(
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
        );
        expect(found, isNotNull);
        expect(found!.deviceProduct, equals('iPhone 15 Pro'));
        expect(found.deviceOsVersion, equals('17.4'));
        expect(found.updatedAt.isAfter(existingDevice.updatedAt), isTrue);
      },
    );
  });
}
