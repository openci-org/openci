// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_dao.dart';

// ignore_for_file: type=lint
mixin _$SecretDaoMixin on DatabaseAccessor<AppDatabase> {
  $TeamsTable get teams => attachedDatabase.teams;
  $SecretsTable get secrets => attachedDatabase.secrets;
  SecretDaoManager get managers => SecretDaoManager(this);
}

class SecretDaoManager {
  final _$SecretDaoMixin _db;
  SecretDaoManager(this._db);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db.attachedDatabase, _db.teams);
  $$SecretsTableTableManager get secrets =>
      $$SecretsTableTableManager(_db.attachedDatabase, _db.secrets);
}
