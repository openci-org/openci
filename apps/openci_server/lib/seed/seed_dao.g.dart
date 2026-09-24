// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seed_dao.dart';

// ignore_for_file: type=lint
mixin _$SeedDaoMixin on DatabaseAccessor<AppDatabase> {
  $TeamsTable get teams => attachedDatabase.teams;
  $BuildJobsTable get buildJobs => attachedDatabase.buildJobs;
  $TeamMembersTable get teamMembers => attachedDatabase.teamMembers;
  SeedDaoManager get managers => SeedDaoManager(this);
}

class SeedDaoManager {
  final _$SeedDaoMixin _db;
  SeedDaoManager(this._db);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db.attachedDatabase, _db.teams);
  $$BuildJobsTableTableManager get buildJobs =>
      $$BuildJobsTableTableManager(_db.attachedDatabase, _db.buildJobs);
  $$TeamMembersTableTableManager get teamMembers =>
      $$TeamMembersTableTableManager(_db.attachedDatabase, _db.teamMembers);
}
