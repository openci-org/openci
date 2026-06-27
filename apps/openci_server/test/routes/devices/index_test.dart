import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/device_table.dart';
import 'package:test/test.dart';

import '../../../routes/devices/index.dart' as route;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('GET /devices (integration with memory DB)', () {
    test(
      'responds with 401 Unauthorized when unauthorized (uid is null)',
      () async {
        final context = TestRequestContext(
          path: '/devices',
          method: HttpMethod.get,
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
      'responds with 200 and empty list when user has no registered devices',
      () async {
        final context = TestRequestContext(
          path: '/devices',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as List<dynamic>;
        expect(body, isEmpty);
      },
    );

    test(
      'responds with 200 and devices list when user has registered devices',
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

        final device1 = DriftUserDevice(
          id: 'device-1',
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
          deviceProduct: 'iPhone 15 Pro',
          deviceOsVersion: '17.4',
          createdAt: now,
          updatedAt: now,
        );
        final device2 = DriftUserDevice(
          id: 'device-2',
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000B12345678901F',
          deviceProduct: 'iPad Pro',
          deviceOsVersion: '17.3',
          createdAt: now,
          updatedAt: now,
        );
        final otherUserDevice = DriftUserDevice(
          id: 'device-3',
          userId: 'user-other',
          teamId: 'team-123',
          udid: '00008101-000C12345678901G',
          deviceProduct: 'iPhone SE',
          deviceOsVersion: '16.0',
          createdAt: now,
          updatedAt: now,
        );

        await db.into(db.userDevices).insert(device1);
        await db.into(db.userDevices).insert(device2);
        await db.into(db.userDevices).insert(otherUserDevice);

        final context = TestRequestContext(
          path: '/devices',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as List<dynamic>;
        expect(body, hasLength(2));

        final resultIds = body.map((d) => d['id'] as String).toList();
        expect(resultIds, containsAll(['device-1', 'device-2']));
        expect(resultIds, isNot(contains('device-3')));

        final device1Data = body.firstWhere((d) => d['id'] == 'device-1');
        expect(device1Data['userId'], equals('user-123'));
        expect(device1Data['teamId'], equals('team-123'));
        expect(device1Data['udid'], equals('00008101-000A12345678901E'));
        expect(device1Data['deviceProduct'], equals('iPhone 15 Pro'));
        expect(device1Data['deviceOsVersion'], equals('17.4'));
      },
    );
  });
}
