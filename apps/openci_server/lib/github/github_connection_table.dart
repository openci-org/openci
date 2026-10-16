import 'package:drift/drift.dart';
import 'package:openci_server/team/team_table.dart';

enum GitHubConnectionStatus { active, suspended, removed }

enum GitHubAccountType { user, organization }

@DataClassName('DriftGitHubConnection')
class GitHubConnections extends Table {
  TextColumn get id => text()();
  TextColumn get teamId =>
      text().references(Teams, #id, onDelete: KeyAction.cascade)();
  TextColumn get githubApiBaseUrl => text()();
  IntColumn get githubAppId => integer()();
  IntColumn get installationId => integer()();
  IntColumn get accountId => integer()();
  TextColumn get accountType =>
      text().map(const GitHubAccountTypeConverter())();
  TextColumn get accountLogin => text()();
  TextColumn get verifiedByUserId => text()();
  IntColumn get verifiedByGitHubUserId =>
      integer().named('verified_by_github_user_id')();
  DateTimeColumn get verifiedAt => dateTime()();
  TextColumn get status => textEnum<GitHubConnectionStatus>()();

  @override
  String get tableName => 'github_connections';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {githubApiBaseUrl, githubAppId, installationId},
  ];
}

class GitHubAccountTypeConverter
    extends TypeConverter<GitHubAccountType, String>
    with JsonTypeConverter<GitHubAccountType, String> {
  const GitHubAccountTypeConverter();

  @override
  GitHubAccountType fromSql(String fromDb) => switch (fromDb) {
    'User' => GitHubAccountType.user,
    'Organization' => GitHubAccountType.organization,
    _ => throw const FormatException('Unknown GitHub account type'),
  };

  @override
  String toSql(GitHubAccountType value) => switch (value) {
    GitHubAccountType.user => 'User',
    GitHubAccountType.organization => 'Organization',
  };
}
