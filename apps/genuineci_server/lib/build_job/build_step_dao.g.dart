// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_step_dao.dart';

// ignore_for_file: type=lint
mixin _$BuildStepDaoMixin on DatabaseAccessor<AppDatabase> {
  $BuildJobsTable get buildJobs => attachedDatabase.buildJobs;
  $BuildRunsTable get buildRuns => attachedDatabase.buildRuns;
  $BuildStepsTable get buildSteps => attachedDatabase.buildSteps;
  BuildStepDaoManager get managers => BuildStepDaoManager(this);
}

class BuildStepDaoManager {
  final _$BuildStepDaoMixin _db;
  BuildStepDaoManager(this._db);
  $$BuildJobsTableTableManager get buildJobs =>
      $$BuildJobsTableTableManager(_db.attachedDatabase, _db.buildJobs);
  $$BuildRunsTableTableManager get buildRuns =>
      $$BuildRunsTableTableManager(_db.attachedDatabase, _db.buildRuns);
  $$BuildStepsTableTableManager get buildSteps =>
      $$BuildStepsTableTableManager(_db.attachedDatabase, _db.buildSteps);
}
