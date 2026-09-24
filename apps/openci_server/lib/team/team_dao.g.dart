// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_dao.dart';

// ignore_for_file: type=lint
mixin _$TeamDaoMixin on DatabaseAccessor<AppDatabase> {
  $TeamsTable get teams => attachedDatabase.teams;
  $TeamMembersTable get teamMembers => attachedDatabase.teamMembers;
  TeamDaoManager get managers => TeamDaoManager(this);
}

class TeamDaoManager {
  final _$TeamDaoMixin _db;
  TeamDaoManager(this._db);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db.attachedDatabase, _db.teams);
  $$TeamMembersTableTableManager get teamMembers =>
      $$TeamMembersTableTableManager(_db.attachedDatabase, _db.teamMembers);
}
