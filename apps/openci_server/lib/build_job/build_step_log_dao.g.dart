// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_step_log_dao.dart';

// ignore_for_file: type=lint
mixin _$BuildStepLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $BuildJobsTable get buildJobs => attachedDatabase.buildJobs;
  $BuildRunsTable get buildRuns => attachedDatabase.buildRuns;
  $BuildStepsTable get buildSteps => attachedDatabase.buildSteps;
  $BuildStepLogsTable get buildStepLogs => attachedDatabase.buildStepLogs;
  BuildStepLogDaoManager get managers => BuildStepLogDaoManager(this);
}

class BuildStepLogDaoManager {
  final _$BuildStepLogDaoMixin _db;
  BuildStepLogDaoManager(this._db);
  $$BuildJobsTableTableManager get buildJobs =>
      $$BuildJobsTableTableManager(_db.attachedDatabase, _db.buildJobs);
  $$BuildRunsTableTableManager get buildRuns =>
      $$BuildRunsTableTableManager(_db.attachedDatabase, _db.buildRuns);
  $$BuildStepsTableTableManager get buildSteps =>
      $$BuildStepsTableTableManager(_db.attachedDatabase, _db.buildSteps);
  $$BuildStepLogsTableTableManager get buildStepLogs =>
      $$BuildStepLogsTableTableManager(_db.attachedDatabase, _db.buildStepLogs);
}
