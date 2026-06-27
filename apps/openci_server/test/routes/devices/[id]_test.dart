import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/device_table.dart';
import 'package:test/test.dart';

import '../../../routes/devices/[id].dart' as route;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('DELETE /devices/[id] (integration with memory DB)', () {
    test(
      'responds with 401 Unauthorized when unauthorized (uid is null)',
      () async {
        final context = TestRequestContext(
          path: '/devices/device-123',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await route.onRequest(context.context, 'device-123');

        expect(response.statusCode, equals(HttpStatus.unauthorized));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Authentication required'));
      },
    );

    test(
      'responds with 404 Not Found when device does not exist',
      () async {
        final context = TestRequestContext(
          path: '/devices/device-123',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context, 'device-123');

        expect(response.statusCode, equals(HttpStatus.notFound));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Device not found'));
      },
    );

    test(
      'responds with 404 Not Found when device belongs to another user',
      () async {
        final now = DateTime.now().toUtc();

        final team = DriftTeam(
          id: 'team-123',
          name: 'Test Team',
          installationIds: const [],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );
        await db.into(db.teams).insert(team);

        final device = DriftUserDevice(
          id: 'device-1',
          userId: 'user-other',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
          deviceProduct: 'iPhone 15 Pro',
          deviceOsVersion: '17.4',
          createdAt: now,
          updatedAt: now,
        );
        await db.into(db.userDevices).insert(device);

        final context = TestRequestContext(
          path: '/devices/device-1',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context, 'device-1');

        expect(response.statusCode, equals(HttpStatus.notFound));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Device not found'));
      },
    );

    test(
      'responds with 200 and success true when device is deleted successfully',
      () async {
        final now = DateTime.now().toUtc();

        final team = DriftTeam(
          id: 'team-123',
          name: 'Test Team',
          installationIds: const [],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );
        await db.into(db.teams).insert(team);

        final device = DriftUserDevice(
          id: 'device-1',
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
          deviceProduct: 'iPhone 15 Pro',
          deviceOsVersion: '17.4',
          createdAt: now,
          updatedAt: now,
        );
        await db.into(db.userDevices).insert(device);

        final context = TestRequestContext(
          path: '/devices/device-1',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context, 'device-1');

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final devices = await db.deviceDao.getDevicesByUserId('user-123');
        expect(devices, isEmpty);
      },
    );
  });
}
