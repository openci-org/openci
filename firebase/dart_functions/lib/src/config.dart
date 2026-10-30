import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_shared/openci_shared.dart';

part 'config.freezed.dart';

@Freezed(toStringOverride: false)
abstract class Config with _$Config {
  const factory Config({
    required String serverUrl,
    required String internalApiKey,
    String? sentryDsn,
  }) = _Config;

  factory Config.fromEnvironment({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    return Config(
      serverUrl: getRequiredEnv('OPENCI_SERVER_URL', environment: env),
      internalApiKey: getRequiredEnv('INTERNAL_API_KEY', environment: env),
      sentryDsn: env['SENTRY_DSN'],
    );
  }
}
