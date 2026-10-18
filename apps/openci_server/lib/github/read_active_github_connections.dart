import 'dart:io';

import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_server/github/parse_github_api_base_uri.dart';

Future<List<DriftGitHubConnection>> readActiveGitHubConnections({
  required AppDatabase db,
  required String teamId,
  Map<String, String>? environment,
}) async {
  final env = environment ?? Platform.environment;
  final apiBaseUrl = parseGitHubApiBaseUri(
    env['GITHUB_API_BASE_URL'],
  ).toString();
  final appId = int.tryParse(env['GITHUB_APP_ID']?.trim() ?? '', radix: 10);
  if (appId == null || appId <= 0) {
    throw StateError('GITHUB_APP_ID must be a positive integer');
  }

  try {
    return await (db.select(db.gitHubConnections)..where(
          (connection) =>
              connection.teamId.equals(teamId) &
              connection.githubApiBaseUrl.equals(apiBaseUrl) &
              connection.githubAppId.equals(appId) &
              connection.status.equalsValue(GitHubConnectionStatus.active),
        ))
        .get();
  } catch (_) {
    throw StateError('Failed to read GitHub connections');
  }
}
