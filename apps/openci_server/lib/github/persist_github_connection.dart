import 'dart:io';

import 'package:meta/meta.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/decrypt_github_connection_token.dart';
import 'package:openci_server/github/github_connection_exception.dart';
import 'package:openci_server/github/parse_github_api_base_uri.dart';
import 'package:openci_server/github/read_github_connection_session.dart';
import 'package:openci_server/github/save_github_connection_and_consume_session.dart';
import 'package:openci_server/github/verify_github_installation.dart';

Future<DriftGitHubConnection?> persistGitHubConnection({
  required AppDatabase db,
  required String reference,
  required String userId,
  required String teamId,
  required int installationId,
  @visibleForTesting Map<String, String>? environment,
}) async {
  final session = await readGitHubConnectionSession(
    db: db,
    reference: reference,
    userId: userId,
    teamId: teamId,
  );
  if (session == null) {
    throw const InvalidGitHubConnectionSessionException();
  }

  final env = Map<String, String>.unmodifiable(
    environment ?? Platform.environment,
  );
  final apiBaseUri = parseGitHubApiBaseUri(env['GITHUB_API_BASE_URL']);
  final accessToken = await decryptGitHubConnectionToken(
    session.encryptedAccessToken!,
    env,
  );
  final installation = await verifyGitHubInstallation(
    accessToken: accessToken,
    installationId: installationId,
    expectedGitHubUserId: session.githubUserId,
    environment: env,
  );
  if (installation == null) {
    throw const GitHubConnectionException(
      'GitHub permissions required',
      failure: GitHubConnectionFailure.permissionsRequired,
    );
  }

  return saveGitHubConnectionAndConsumeSession(
    db: db,
    reference: reference,
    teamId: teamId,
    githubApiBaseUrl: apiBaseUri.toString(),
    verifiedInstallation: installation,
    verifiedByUserId: userId,
    verifiedByGitHubUserId: session.githubUserId,
    verifiedAt: DateTime.now().toUtc(),
  );
}
