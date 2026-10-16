import 'package:drift/drift.dart';
import 'package:openci_server/team/team_table.dart';

@DataClassName('DriftGitHubConnectionRequest')
class GitHubConnectionRequests extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get teamId =>
      text().references(Teams, #id, onDelete: KeyAction.cascade)();
  TextColumn get stateHash => text().unique()();
  TextColumn get codeVerifier => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  String get tableName => 'github_connection_requests';

  @override
  Set<Column> get primaryKey => {id};
}
