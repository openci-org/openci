import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';

const defaultGitHubApiBaseUrl = 'https://api.github.com';

const defaultGitHubBaseUrl = 'https://github.com';

Future<String> getGitHubApiBaseUrl(String? teamId) async {
  if (teamId == null) return defaultGitHubApiBaseUrl;

  final teamDoc =
      await firestore.collection(teamsCollection).doc(teamId).get();
  if (!teamDoc.exists) return defaultGitHubApiBaseUrl;

  final data = teamDoc.data();
  return (data?['githubApiBaseUrl'] as String?) ?? defaultGitHubApiBaseUrl;
}

Future<String> getGitHubBaseUrl(String? teamId) async {
  if (teamId == null) return defaultGitHubBaseUrl;

  final teamDoc =
      await firestore.collection(teamsCollection).doc(teamId).get();
  if (!teamDoc.exists) return defaultGitHubBaseUrl;

  final data = teamDoc.data();
  return (data?['githubBaseUrl'] as String?) ?? defaultGitHubBaseUrl;
}

String getApiBaseUrlFromTeamData(Map<String, dynamic>? teamData) {
  return (teamData?['githubApiBaseUrl'] as String?) ?? defaultGitHubApiBaseUrl;
}

String getBaseUrlFromTeamData(Map<String, dynamic>? teamData) {
  return (teamData?['githubBaseUrl'] as String?) ?? defaultGitHubBaseUrl;
}

String graphqlEndpoint(String apiBaseUrl) {
  if (apiBaseUrl == defaultGitHubApiBaseUrl) {
    return '$apiBaseUrl/graphql';
  }
  final uri = Uri.parse(apiBaseUrl);
  return '${uri.scheme}://${uri.host}/api/graphql';
}
