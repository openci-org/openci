import 'package:openci_server/database.dart';
import 'package:openci_server/github/consume_github_connection_session.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/save_github_connection.dart';

Future<DriftGitHubConnection?> saveGitHubConnectionAndConsumeSession({
  required AppDatabase db,
  required String reference,
  required String teamId,
  required String githubApiBaseUrl,
  required GitHubInstallation verifiedInstallation,
  required String verifiedByUserId,
  required int verifiedByGitHubUserId,
  required DateTime verifiedAt,
}) async {
  try {
    return await db.transaction(() async {
      final connection = await saveGitHubConnection(
        db: db,
        teamId: teamId,
        githubApiBaseUrl: githubApiBaseUrl,
        verifiedInstallation: verifiedInstallation,
        verifiedByUserId: verifiedByUserId,
        verifiedByGitHubUserId: verifiedByGitHubUserId,
        verifiedAt: verifiedAt,
      );
      if (connection == null) return null;

      final consumed = await consumeGitHubConnectionSession(
        db: db,
        reference: reference,
        userId: verifiedByUserId,
        teamId: teamId,
      );
      if (!consumed) {
        // Throw inside the transaction so the saved connection is rolled back.
        throw const InvalidGitHubConnectionSessionException();
      }
      return connection;
    });
  } on InvalidGitHubConnectionSessionException {
    rethrow;
  } catch (_) {
    throw StateError('Failed to save GitHub connection and consume session');
  }
}

class InvalidGitHubConnectionSessionException implements Exception {
  const InvalidGitHubConnectionSessionException();
}
