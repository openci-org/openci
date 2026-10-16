import 'package:openci_server/github/github_repository_url.dart';

Uri buildGitHubAuthorizationUrl({
  required String clientId,
  required Uri redirectUri,
  required String state,
  required String codeChallenge,
  Map<String, String>? environment,
}) {
  final baseUrl = Uri.parse(
    githubRepositoryBaseUrl(environment: environment),
  );

  return baseUrl.replace(
    path: '${baseUrl.path}/login/oauth/authorize',
    queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri.toString(),
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    },
  );
}
