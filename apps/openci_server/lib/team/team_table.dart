import 'dart:convert';
import 'package:drift/drift.dart';

class IntListConverter extends TypeConverter<List<int>, String> {
  const IntListConverter();
  @override
  List<int> fromSql(String fromDb) {
    return (jsonDecode(fromDb) as List<dynamic>).cast<int>();
  }

  @override
  String toSql(List<int> value) {
    return jsonEncode(value);
  }
}

@DataClassName('DriftTeam')
class Teams extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get githubBaseUrl => text().nullable()();
  TextColumn get githubApiBaseUrl => text().nullable()();
  TextColumn get installationIds => text().map(const IntListConverter())();
  BoolColumn get aiEnabled => boolean()();
  IntColumn get runNumber => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DriftTeamMember')
class TeamMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get teamId => text()();
  TextColumn get userId => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {teamId, userId}
      ];
}
