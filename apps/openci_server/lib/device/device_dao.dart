import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/device_table.dart';
import 'package:uuid/uuid.dart';

part 'device_dao.g.dart';

@DriftAccessor(tables: [UserDevices])
class DeviceDao extends DatabaseAccessor<AppDatabase> with _$DeviceDaoMixin {
  DeviceDao(super.attachedDatabase);

  Future<List<DriftUserDevice>> getDevicesByUserId(String uid) {
    return (select(userDevices)..where((d) => d.userId.equals(uid))).get();
  }

  Future<int> deleteDevice(String id, String userId) {
    return (delete(
      userDevices,
    )..where((d) => d.id.equals(id) & d.userId.equals(userId))).go();
  }

  Future<DriftUserDevice?> findDevice({
    required String userId,
    required String teamId,
    required String udid,
  }) {
    return (select(userDevices)..where(
          (d) =>
              d.userId.equals(userId) &
              d.teamId.equals(teamId) &
              d.udid.equals(udid),
        ))
        .getSingleOrNull();
  }

  Future<DriftUserDevice> createDevice({
    required String userId,
    required String teamId,
    required String udid,
    required String deviceProduct,
    required String deviceOsVersion,
  }) async {
    final existing = await findDevice(
      userId: userId,
      teamId: teamId,
      udid: udid,
    );
    if (existing != null) {
      throw DeviceAlreadyExistsException(
        'Device with UDID $udid is already registered for this user and team.',
      );
    }

    final now = DateTime.now().toUtc();
    final newDevice = DriftUserDevice(
      id: const Uuid().v4(),
      userId: userId,
      teamId: teamId,
      udid: udid,
      deviceProduct: deviceProduct,
      deviceOsVersion: deviceOsVersion,
      createdAt: now,
      updatedAt: now,
    );
    await into(userDevices).insert(newDevice);
    return newDevice;
  }

  Future<DriftUserDevice> updateDevice({
    required DriftUserDevice existing,
    required String deviceProduct,
    required String deviceOsVersion,
  }) async {
    final now = DateTime.now().toUtc();
    final updated = DriftUserDevice(
      id: existing.id,
      userId: existing.userId,
      teamId: existing.teamId,
      udid: existing.udid,
      deviceProduct: deviceProduct,
      deviceOsVersion: deviceOsVersion,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    await update(userDevices).replace(updated);
    return updated;
  }
}

class DeviceAlreadyExistsException implements Exception {
  final String message;
  DeviceAlreadyExistsException(this.message);

  @override
  String toString() => 'DeviceAlreadyExistsException: $message';
}
