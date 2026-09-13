// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'udid_request_dao.dart';

// ignore_for_file: type=lint
mixin _$UdidRequestDaoMixin on DatabaseAccessor<AppDatabase> {
  $TeamsTable get teams => attachedDatabase.teams;
  $UdidRequestsTable get udidRequests => attachedDatabase.udidRequests;
  UdidRequestDaoManager get managers => UdidRequestDaoManager(this);
}

class UdidRequestDaoManager {
  final _$UdidRequestDaoMixin _db;
  UdidRequestDaoManager(this._db);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db.attachedDatabase, _db.teams);
  $$UdidRequestsTableTableManager get udidRequests =>
      $$UdidRequestsTableTableManager(_db.attachedDatabase, _db.udidRequests);
}
