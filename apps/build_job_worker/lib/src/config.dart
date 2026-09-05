import 'dart:io';

import 'package:openci_shared/openci_shared.dart';

class Config {
  const Config({
    required this.serverUrl,
    required this.internalApiKey,
    this.sentryDsn,
  });

  factory Config.fromEnvironment({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;

    return Config(
      serverUrl: getRequiredEnv('OPENCI_SERVER_URL', environment: env),
      internalApiKey: getRequiredEnv('INTERNAL_API_KEY', environment: env),
      sentryDsn: env['SENTRY_DSN'],
    );
  }

  final String serverUrl;
  final String internalApiKey;
  final String? sentryDsn;
}
