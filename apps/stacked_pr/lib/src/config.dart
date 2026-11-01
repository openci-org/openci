import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:path/path.dart' as p;

class AppConfig {
  AppConfig({
    required this.githubUrl,
    required this.appId,
    required this.privateKey,
    required this.secret,
    required this.dataDir,
    this.port = 3000,
    this.host = '0.0.0.0',
    this.autoRestack = true,
    Set<String>? allowedRepos,
  }) : allowedRepos = allowedRepos ?? {};

  final Uri githubUrl;
  final String appId, secret, dataDir, host;
  final RSAPrivateKey privateKey;
  final int port;
  final bool autoRestack;
  final Set<String> allowedRepos;
  Uri get apiUrl => githubUrl.host == 'github.com'
      ? Uri.parse('https://api.github.com')
      : githubUrl.resolve('/api/v3');

  factory AppConfig.fromEnvironment(Map<String, String> env) {
    String required(String name) {
      final value = env[name]?.trim();
      if (value == null || value.isEmpty) throw FormatException('$name is required');
      return value;
    }

    final origin = Uri.parse(required('GITHUB_URL'));
    if (origin.scheme != 'https' ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        !['', '/'].contains(origin.path) ||
        origin.hasQuery ||
        origin.hasFragment) {
      throw const FormatException('GITHUB_URL must be an HTTPS origin');
    }
    final id = required('GITHUB_APP_ID');
    if (!RegExp(r'^\d+$').hasMatch(id)) {
      throw const FormatException('GITHUB_APP_ID must be numeric');
    }
    final key = RSAPrivateKey(File(required('GITHUB_PRIVATE_KEY_FILE')).readAsStringSync());
    JWT({'test': true}).sign(key, algorithm: JWTAlgorithm.RS256);
    final secret = required('GITHUB_WEBHOOK_SECRET');
    if (secret.length < 32) {
      throw const FormatException('Use a webhook secret of at least 32 characters');
    }
    final port = int.parse(env['PORT'] ?? '3000');
    if (port < 1 || port > 65535) throw const FormatException('Invalid PORT');
    if (env.containsKey('AUTO_RESTACK') && !['true', 'false'].contains(env['AUTO_RESTACK'])) {
      throw const FormatException('AUTO_RESTACK must be true or false');
    }
    return AppConfig(
      githubUrl: Uri.parse(origin.origin),
      appId: id,
      privateKey: key,
      secret: secret,
      dataDir: p.absolute(env['DATA_DIR'] ?? 'data'),
      port: port,
      host: env['HOST'] ?? '0.0.0.0',
      autoRestack: env['AUTO_RESTACK'] != 'false',
      allowedRepos: (env['ALLOWED_REPOSITORIES'] ?? '')
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toSet(),
    );
  }
}
