import 'dart:io';

import 'package:openci_shared/openci_shared.dart';
import 'package:yaml/yaml.dart';

class Config {
  Config({
    required this.serverUrl,
    required this.baseVmName,
    required this.internalApiKey,
    required this.orchardServiceAccountName,
    required this.orchardServiceAccountToken,
    this.orchardApiUrl = 'https://orchard-controller:6120',
    this.sentryDsn,
  });

  final String serverUrl;
  final String baseVmName;
  final String internalApiKey;
  final String? sentryDsn;

  final String orchardApiUrl;
  final String orchardServiceAccountName;
  final String orchardServiceAccountToken;

  static ({String name, String token}) _loadOrchardCredentials() {
    final homeDir = Platform.environment['HOME'] ?? '';
    final orchardConfigFile = File('$homeDir/.orchard/orchard.yml');
    if (!orchardConfigFile.existsSync()) {
      throw StateError(
        'Orchard configuration file not found at ${orchardConfigFile.path}.',
      );
    }

    final yamlData = loadYaml(orchardConfigFile.readAsStringSync());
    if (yamlData is! Map) {
      throw StateError('Invalid YAML content in ${orchardConfigFile.path}.');
    }

    final defaultContext = yamlData['default-context']?.toString() ?? 'default';
    final contexts = yamlData['contexts'] as Map?;
    final currentContext = contexts?[defaultContext] as Map?;

    final name = currentContext?['serviceAccountName']?.toString().trim();
    final token = currentContext?['serviceAccountToken']?.toString().trim();

    if (name == null || name.isEmpty) {
      throw StateError(
        'serviceAccountName not found in context "$defaultContext" in ${orchardConfigFile.path}.',
      );
    }

    if (token == null || token.isEmpty) {
      throw StateError(
        'serviceAccountToken not found in context "$defaultContext" in ${orchardConfigFile.path}.',
      );
    }

    return (name: name, token: token);
  }

  factory Config.fromEnvironment() {
    final baseVmName = Platform.environment['BASE_VM_NAME'] ?? 'tahoe-base';

    final orchardCredentials = _loadOrchardCredentials();

    return Config(
      serverUrl: getRequiredEnv('OPENCI_SERVER_URL'),
      baseVmName: baseVmName,
      internalApiKey: getRequiredEnv('INTERNAL_API_KEY'),
      sentryDsn: Platform.environment['SENTRY_DSN'],
      orchardServiceAccountName: orchardCredentials.name,
      orchardServiceAccountToken: orchardCredentials.token,
    );
  }
}
