import 'dart:io';

import 'package:openci_shared/openci_shared.dart';

class Config {
  Config({
    required this.internalApiKey,
    this.sentryDsn,
  });

  final String internalApiKey;
  final String? sentryDsn;

  factory Config.fromEnvironment() {
    return Config(
      internalApiKey: getRequiredEnv('INTERNAL_API_KEY'),
      sentryDsn: Platform.environment['SENTRY_DSN'],
    );
  }
}
