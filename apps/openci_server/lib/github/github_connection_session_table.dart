import 'package:drift/drift.dart';
import 'package:openci_server/team/team_table.dart';

@UseRowClass(DriftGitHubConnectionSession)
class GitHubConnectionSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get teamId =>
      text().references(Teams, #id, onDelete: KeyAction.cascade)();
  IntColumn get githubUserId => integer()();
  TextColumn get referenceHash => text().unique()();
  // Nullable so consumption or cleanup can remove the token.
  TextColumn get encryptedAccessToken => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get consumedAt => dateTime().nullable()();

  @override
  String get tableName => 'github_connection_sessions';

  @override
  Set<Column> get primaryKey => {id};
}

class DriftGitHubConnectionSession {
  const DriftGitHubConnectionSession({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.githubUserId,
    required this.referenceHash,
    required this.encryptedAccessToken,
    required this.createdAt,
    required this.expiresAt,
    this.consumedAt,
  });

  final String id;
  final String userId;
  final String teamId;
  final int githubUserId;
  final String referenceHash;
  final String? encryptedAccessToken;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? consumedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'teamId': teamId,
    'githubUserId': githubUserId,
    'referenceHash': '[REDACTED]',
    'encryptedAccessToken': '[REDACTED]',
    'createdAt': createdAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'consumedAt': consumedAt?.toUtc().toIso8601String(),
  };

  @override
  String toString() => 'DriftGitHubConnectionSession(${toJson()})';
}
