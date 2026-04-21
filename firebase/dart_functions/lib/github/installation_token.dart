import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:github_client/api/export.dart';

import '../secret_manager.dart';
import '../util/github_urls.dart';

String createGitHubAppJwt({required String appId, required String privateKey}) {
  final now = DateTime.now().toUtc();
  final iatSeconds =
      now.subtract(const Duration(seconds: 60)).millisecondsSinceEpoch ~/ 1000;
  final expSeconds =
      now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000;

  final jwt = JWT({'iat': iatSeconds, 'exp': expSeconds, 'iss': appId});

  return jwt.sign(
    RSAPrivateKey(privateKey),
    algorithm: JWTAlgorithm.RS256,
    noIssueAt: true,
  );
}

Dio createGitHubDio(
  String token, {
  String apiBaseUrl = defaultGitHubApiBaseUrl,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    ),
  );
  dio.addSentry();
  return dio;
}

Future<({String token, String expiresAt})> getInstallationToken(
  int installationId, {
  String apiBaseUrl = defaultGitHubApiBaseUrl,
}) async {
  final appId = await accessSecret('GITHUB_APP_ID');
  final privateKey = await accessSecret('GITHUB_PRIVATE_KEY');

  final jwtToken = createGitHubAppJwt(appId: appId, privateKey: privateKey);
  final appDio = createGitHubDio(jwtToken, apiBaseUrl: apiBaseUrl);

  final client = GitHubClient(appDio);
  final result = await client.apps.appsCreateInstallationAccessToken(
    installationId: installationId,
  );

  appDio.close();

  return (token: result.token, expiresAt: result.expiresAt);
}
