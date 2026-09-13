// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_job_dao.dart';

// ignore_for_file: type=lint
mixin _$BuildJobDaoMixin on DatabaseAccessor<AppDatabase> {
  $BuildJobsTable get buildJobs => attachedDatabase.buildJobs;
  BuildJobDaoManager get managers => BuildJobDaoManager(this);
}

class BuildJobDaoManager {
  final _$BuildJobDaoMixin _db;
  BuildJobDaoManager(this._db);
  $$BuildJobsTableTableManager get buildJobs =>
      $$BuildJobsTableTableManager(_db.attachedDatabase, _db.buildJobs);
}
