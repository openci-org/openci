import 'dart:io';

import 'package:openci_shared/openci_shared.dart';

class Config {
  const Config({
    required this.serverUrl,
    required this.internalApiKey,
    required this.orchardServiceAccountName,
    required this.orchardServiceAccountToken,
    this.baseVmName = 'base-macos',
    this.orchardApiUrl = 'https://orchard-controller:6120',
    this.lokiUrl = 'http://192.168.64.1:3100',
    this.internalLokiUrl = 'http://loki:3100',
    this.sentryDsn,
  });

  factory Config.fromEnvironment({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;

    return Config(
      serverUrl: getRequiredEnv('OPENCI_SERVER_URL', environment: env),
      internalApiKey: getRequiredEnv('INTERNAL_API_KEY', environment: env),
      orchardServiceAccountName: getRequiredEnv(
        'ORCHARD_SERVICE_ACCOUNT_NAME',
        environment: env,
      ),
      orchardServiceAccountToken: getRequiredEnv(
        'ORCHARD_SERVICE_ACCOUNT_TOKEN',
        environment: env,
      ),
      baseVmName: env['BASE_VM_NAME'] ?? 'base-macos',
      orchardApiUrl:
          env['ORCHARD_API_URL'] ?? 'https://orchard-controller:6120',
      lokiUrl: env['LOKI_URL_FOR_VM'] ?? 'http://192.168.64.1:3100',
      internalLokiUrl: env['LOKI_URL'] ?? 'http://loki:3100',
      sentryDsn: env['SENTRY_DSN'],
    );
  }

  final String serverUrl;
  final String internalApiKey;
  final String? sentryDsn;
  final String baseVmName;
  final String orchardApiUrl;
  final String orchardServiceAccountName;
  final String orchardServiceAccountToken;
  final String lokiUrl;
  final String internalLokiUrl;
}
