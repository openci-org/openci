// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_heartbeat_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkerHeartbeatDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkerHeartbeatsTable get workerHeartbeats =>
      attachedDatabase.workerHeartbeats;
  WorkerHeartbeatDaoManager get managers => WorkerHeartbeatDaoManager(this);
}

class WorkerHeartbeatDaoManager {
  final _$WorkerHeartbeatDaoMixin _db;
  WorkerHeartbeatDaoManager(this._db);
  $$WorkerHeartbeatsTableTableManager get workerHeartbeats =>
      $$WorkerHeartbeatsTableTableManager(
        _db.attachedDatabase,
        _db.workerHeartbeats,
      );
}
