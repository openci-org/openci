import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

String generateGitHubAppJwt({
  required String appId,
  required String privateKeyPem,
}) {
  final parsedAppId = int.tryParse(appId.trim());
  if (parsedAppId == null) {
    throw FormatException(
      'Invalid GitHub App ID: "$appId". GitHub App ID must be a valid integer.',
    );
  }
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final jwt = JWT({
    'iat': nowSeconds - 60,
    'exp': nowSeconds + 540,
    'iss': parsedAppId,
  });
  return jwt.sign(
    RSAPrivateKey(privateKeyPem),
    algorithm: JWTAlgorithm.RS256,
    noIssueAt: true,
  );
}
