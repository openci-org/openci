import 'package:openci_server/database.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_server/github/parse_github_api_base_uri.dart';
import 'package:uuid/uuid.dart';

Future<DriftGitHubConnection> insertGitHubConnection({
  required AppDatabase db,
  required String teamId,
  required String githubApiBaseUrl,
  required GitHubInstallation verifiedInstallation,
  required String verifiedByUserId,
  required int verifiedByGitHubUserId,
  required DateTime verifiedAt,
}) async {
  if (verifiedInstallation.suspendedAt != null) {
    throw ArgumentError('An active GitHub installation is required');
  }

  final connection = GitHubConnectionsCompanion.insert(
    id: const Uuid().v4(),
    teamId: teamId,
    githubApiBaseUrl: parseGitHubApiBaseUri(githubApiBaseUrl).toString(),
    githubAppId: verifiedInstallation.appId,
    installationId: verifiedInstallation.id,
    accountId: verifiedInstallation.accountId,
    accountType: const GitHubAccountTypeConverter().fromJson(
      verifiedInstallation.accountType,
    ),
    accountLogin: verifiedInstallation.accountLogin,
    verifiedByUserId: verifiedByUserId,
    verifiedByGitHubUserId: verifiedByGitHubUserId,
    verifiedAt: verifiedAt.toUtc(),
    status: GitHubConnectionStatus.active,
  );

  try {
    return await db.into(db.gitHubConnections).insertReturning(connection);
  } catch (_) {
    throw StateError('Failed to insert GitHub connection');
  }
}
