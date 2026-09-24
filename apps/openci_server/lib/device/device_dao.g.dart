// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_dao.dart';

// ignore_for_file: type=lint
mixin _$DeviceDaoMixin on DatabaseAccessor<AppDatabase> {
  $TeamsTable get teams => attachedDatabase.teams;
  $UserDevicesTable get userDevices => attachedDatabase.userDevices;
  DeviceDaoManager get managers => DeviceDaoManager(this);
}

class DeviceDaoManager {
  final _$DeviceDaoMixin _db;
  DeviceDaoManager(this._db);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db.attachedDatabase, _db.teams);
  $$UserDevicesTableTableManager get userDevices =>
      $$UserDevicesTableTableManager(_db.attachedDatabase, _db.userDevices);
}
