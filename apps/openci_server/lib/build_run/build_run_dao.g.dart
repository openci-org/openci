// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_run_dao.dart';

// ignore_for_file: type=lint
mixin _$BuildRunDaoMixin on DatabaseAccessor<AppDatabase> {
  $BuildJobsTable get buildJobs => attachedDatabase.buildJobs;
  $BuildRunsTable get buildRuns => attachedDatabase.buildRuns;
  BuildRunDaoManager get managers => BuildRunDaoManager(this);
}

class BuildRunDaoManager {
  final _$BuildRunDaoMixin _db;
  BuildRunDaoManager(this._db);
  $$BuildJobsTableTableManager get buildJobs =>
      $$BuildJobsTableTableManager(_db.attachedDatabase, _db.buildJobs);
  $$BuildRunsTableTableManager get buildRuns =>
      $$BuildRunsTableTableManager(_db.attachedDatabase, _db.buildRuns);
}
