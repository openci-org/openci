import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_shared/openci_shared.dart';

part 'config.freezed.dart';

@Freezed(toStringOverride: false)
abstract class Config with _$Config {
  const factory Config({
    required String serverUrl,
    required String internalApiKey,
    required String orchardServiceAccountName,
    required String orchardServiceAccountToken,
    @Default('base-macos') String baseVmName,
    @Default('https://orchard-controller:6120') String orchardApiUrl,
    @Default('http://192.168.64.1:3100') String lokiUrl,
    @Default('http://loki:3100') String internalLokiUrl,
    String? sentryDsn,
  }) = _Config;

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
}
