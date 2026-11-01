import 'dart:io';
import 'package:dotenv/dotenv.dart';

Map<String, String> loadEnvironment() {
  final dotenv = DotEnv(quiet: true)..load();
  return {
    for (final name in [
      'GITHUB_URL',
      'GITHUB_APP_ID',
      'GITHUB_PRIVATE_KEY_FILE',
      'GITHUB_WEBHOOK_SECRET',
      'DATA_DIR',
      'PORT',
      'HOST',
      'AUTO_RESTACK',
      'ALLOWED_REPOSITORIES',
      'GITHUB_CA_FILE',
      'GIT_SSL_CAINFO',
      'HTTP_PROXY',
      'HTTPS_PROXY',
      'NO_PROXY',
      'http_proxy',
      'https_proxy',
      'no_proxy',
    ])
      if (dotenv[name] != null) name: dotenv[name]!,
    ...Platform.environment,
  };
}
