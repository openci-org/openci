import 'package:drift/drift.dart';
import 'package:openci_server/team/team_table.dart';

@DataClassName('DriftSecret')
class Secrets extends Table {
  TextColumn get name => text()();
  TextColumn get teamId => text().references(Teams, #id)();
  TextColumn get encryptedValue => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {teamId, name};
}
