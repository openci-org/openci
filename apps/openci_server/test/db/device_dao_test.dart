import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/device_dao.dart';
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
            deviceProduct: 'iPhone 15 Pro',
            deviceOsVersion: '17.4',
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
            deviceProduct: 'iPhone 15 Pro',
            deviceOsVersion: '17.4',
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

    group('findDevice', () {
      test('returns the device if it exists', () async {
        final now = DateTime.now().toUtc();
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

        final found = await db.deviceDao.findDevice(
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
        );

        expect(found, isNotNull);
        expect(found!.id, equals('device-1'));
      });

      test('returns null if the device does not exist', () async {
        final found = await db.deviceDao.findDevice(
          userId: 'user-123',
          teamId: 'team-123',
          udid: 'unknown-udid',
        );

        expect(found, isNull);
      });

      test(
        'returns null if the device with different criteria does not exist but other devices do',
        () async {
          final now = DateTime.now().toUtc();
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

          final foundByUdid = await db.deviceDao.findDevice(
            userId: 'user-123',
            teamId: 'team-123',
            udid: '00008101-000B12345678901F',
          );
          expect(foundByUdid, isNull);

          final foundByUserId = await db.deviceDao.findDevice(
            userId: 'user-456',
            teamId: 'team-123',
            udid: '00008101-000A12345678901E',
          );
          expect(foundByUserId, isNull);

          final foundByTeamId = await db.deviceDao.findDevice(
            userId: 'user-123',
            teamId: 'team-456',
            udid: '00008101-000A12345678901E',
          );
          expect(foundByTeamId, isNull);
        },
      );
    });

    group('createDevice', () {
      test('successfully inserts a new device', () async {
        final device = await db.deviceDao.createDevice(
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
          deviceProduct: 'iPhone 15 Pro',
          deviceOsVersion: '17.4',
        );

        expect(device.id, isNotEmpty);
        expect(device.userId, equals('user-123'));
        expect(device.teamId, equals('team-123'));
        expect(device.udid, equals('00008101-000A12345678901E'));
        expect(device.deviceProduct, equals('iPhone 15 Pro'));
        expect(device.deviceOsVersion, equals('17.4'));

        final found = await db.deviceDao.findDevice(
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
        );
        expect(found, isNotNull);
        expect(found!.id, equals(device.id));
      });

      test(
        'throws DeviceAlreadyExistsException when registering a device with same userId, teamId, and udid',
        () async {
          await db.deviceDao.createDevice(
            userId: 'user-123',
            teamId: 'team-123',
            udid: '00008101-000A12345678901E',
            deviceProduct: 'iPhone 15 Pro',
            deviceOsVersion: '17.4',
          );

          expect(
            () => db.deviceDao.createDevice(
              userId: 'user-123',
              teamId: 'team-123',
              udid: '00008101-000A12345678901E',
              deviceProduct: 'iPhone 15 Pro',
              deviceOsVersion: '17.4',
            ),
            throwsA(isA<DeviceAlreadyExistsException>()),
          );
        },
      );

      test(
        'throws DeviceAlreadyExistsException when registering a device with same userId, teamId, and udid but different OS version',
        () async {
          await db.deviceDao.createDevice(
            userId: 'user-123',
            teamId: 'team-123',
            udid: '00008101-000A12345678901E',
            deviceProduct: 'iPhone 15 Pro',
            deviceOsVersion: '17.4',
          );

          expect(
            () => db.deviceDao.createDevice(
              userId: 'user-123',
              teamId: 'team-123',
              udid: '00008101-000A12345678901E',
              deviceProduct: 'iPhone 15 Pro',
              deviceOsVersion: '18.0',
            ),
            throwsA(isA<DeviceAlreadyExistsException>()),
          );
        },
      );
    });

    group('updateDevice', () {
      test('successfully updates device fields', () async {
        final now = DateTime.now().toUtc();
        final existing = DriftUserDevice(
          id: 'existing-id',
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
          deviceProduct: 'iPhone 14',
          deviceOsVersion: '16.5',
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        );
        await db.into(db.userDevices).insert(existing);

        final updated = await db.deviceDao.updateDevice(
          existing: existing,
          deviceProduct: 'iPhone 15 Pro',
          deviceOsVersion: '17.4',
        );

        expect(updated.id, equals('existing-id'));
        expect(updated.deviceProduct, equals('iPhone 15 Pro'));
        expect(updated.deviceOsVersion, equals('17.4'));

        final found = await db.deviceDao.findDevice(
          userId: 'user-123',
          teamId: 'team-123',
          udid: '00008101-000A12345678901E',
        );
        expect(found, isNotNull);
        expect(found!.deviceProduct, equals('iPhone 15 Pro'));
        expect(found.deviceOsVersion, equals('17.4'));
      });

      test(
        'throws StateError when trying to update a non-existent device',
        () async {
          final now = DateTime.now().toUtc();
          final nonExistent = DriftUserDevice(
            id: 'non-existent-id',
            userId: 'user-123',
            teamId: 'team-123',
            udid: '00008101-000A12345678901E',
            deviceProduct: 'iPhone 14',
            deviceOsVersion: '16.5',
            createdAt: now,
            updatedAt: now,
          );

          expect(
            () => db.deviceDao.updateDevice(
              existing: nonExistent,
              deviceProduct: 'iPhone 15 Pro',
              deviceOsVersion: '17.4',
            ),
            throwsA(isA<StateError>()),
          );
        },
      );
    });
  });
}
