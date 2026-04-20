import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';

/// Default GitHub API base URL (public GitHub).
const defaultGitHubApiBaseUrl = 'https://api.github.com';

/// Default GitHub base URL (public GitHub).
const defaultGitHubBaseUrl = 'https://github.com';

/// Returns the GitHub API base URL for a team.
/// Falls back to `https://api.github.com` if not set.
Future<String> getGitHubApiBaseUrl(String? teamId) async {
  if (teamId == null) return defaultGitHubApiBaseUrl;

  final teamDoc =
      await firestore.collection(teamsCollection).doc(teamId).get();
  if (!teamDoc.exists) return defaultGitHubApiBaseUrl;

  final data = teamDoc.data();
  return (data?['githubApiBaseUrl'] as String?) ?? defaultGitHubApiBaseUrl;
}

/// Returns the GitHub base URL for a team.
/// Falls back to `https://github.com` if not set.
Future<String> getGitHubBaseUrl(String? teamId) async {
  if (teamId == null) return defaultGitHubBaseUrl;

  final teamDoc =
      await firestore.collection(teamsCollection).doc(teamId).get();
  if (!teamDoc.exists) return defaultGitHubBaseUrl;

  final data = teamDoc.data();
  return (data?['githubBaseUrl'] as String?) ?? defaultGitHubBaseUrl;
}

/// Returns the GitHub API base URL from a team data map (avoids extra reads).
String getApiBaseUrlFromTeamData(Map<String, dynamic>? teamData) {
  return (teamData?['githubApiBaseUrl'] as String?) ?? defaultGitHubApiBaseUrl;
}

/// Returns the GitHub base URL from a team data map (avoids extra reads).
String getBaseUrlFromTeamData(Map<String, dynamic>? teamData) {
  return (teamData?['githubBaseUrl'] as String?) ?? defaultGitHubBaseUrl;
}

/// Returns the GraphQL endpoint for the given API base URL.
/// - github.com: `https://api.github.com/graphql`
/// - GHE: `https://<host>/api/graphql`
String graphqlEndpoint(String apiBaseUrl) {
  if (apiBaseUrl == defaultGitHubApiBaseUrl) {
    return '$apiBaseUrl/graphql';
  }
  // GHE: strip /api/v3 suffix if present, then append /api/graphql
  final uri = Uri.parse(apiBaseUrl);
  return '${uri.scheme}://${uri.host}/api/graphql';
}
