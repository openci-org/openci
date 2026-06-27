import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/device_table.dart';

part 'device_dao.g.dart';

@DriftAccessor(tables: [UserDevices])
class DeviceDao extends DatabaseAccessor<AppDatabase> with _$DeviceDaoMixin {
  DeviceDao(super.attachedDatabase);

  Future<List<DriftUserDevice>> getDevicesByUserId(String uid) {
    return (select(userDevices)..where((d) => d.userId.equals(uid))).get();
  }
}
