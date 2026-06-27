import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/device_table.dart';
import 'package:test/test.dart';

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

  group('DeviceDao Tests', () {
    group('getDevicesByUserId', () {
      test(
        'retrieves only devices belonging to the specific user',
        () async {
          final now = DateTime.now().toUtc();

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

          final userDevices = await db.deviceDao.getDevicesByUserId('user-123');
          expect(userDevices, hasLength(2));

          final ids = userDevices.map((d) => d.id).toList();
          expect(ids, containsAll(['device-1', 'device-2']));
          expect(ids, isNot(contains('device-3')));
        },
      );

      test(
        'returns empty list if user has no devices',
        () async {
          final userDevices = await db.deviceDao.getDevicesByUserId(
            'user-unknown',
          );
          expect(userDevices, isEmpty);
        },
      );
    });

    group('deleteDevice', () {
      test(
        'deletes the correct device for the owner',
        () async {
          final now = DateTime.now().toUtc();

          final device = DriftUserDevice(
            id: 'device-1',
            userId: 'user-123',
            teamId: 'team-123',
            udid: '00008101-000A12345678901E',
            createdAt: now,
            updatedAt: now,
          );
          await db.into(db.userDevices).insert(device);

          final deletedCount = await db.deviceDao.deleteDevice(
            'device-1',
            'user-123',
          );
          expect(deletedCount, equals(1));

          final devices = await db.deviceDao.getDevicesByUserId('user-123');
          expect(devices, isEmpty);
        },
      );

      test(
        'does not delete device if user is not the owner',
        () async {
          final now = DateTime.now().toUtc();

          final device = DriftUserDevice(
            id: 'device-1',
            userId: 'user-123',
            teamId: 'team-123',
            udid: '00008101-000A12345678901E',
            createdAt: now,
            updatedAt: now,
          );
          await db.into(db.userDevices).insert(device);

          final deletedCount = await db.deviceDao.deleteDevice(
            'device-1',
            'user-other',
          );
          expect(deletedCount, equals(0));

          final devices = await db.deviceDao.getDevicesByUserId('user-123');
          expect(devices, hasLength(1));
        },
      );
    });
  });
}
