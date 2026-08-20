import 'dart:io';

import 'package:openci_shared/openci_shared.dart';
import 'package:yaml/yaml.dart';

class Config {
  Config({
    required this.serverUrl,
    required this.baseVmName,
    required this.internalApiKey,
    required this.buildJobId,
    required this.orchardServiceAccountName,
    required this.orchardServiceAccountToken,
    this.orchardApiUrl = 'https://orchard-controller:6120',
    this.lokiUrl = 'http://192.168.64.1:3100',
    this.internalLokiUrl = 'http://loki:3100',
    this.sentryDsn,
  });

  final String serverUrl;
  final String baseVmName;
  final String internalApiKey;
  final String buildJobId;
  final String? sentryDsn;

  final String orchardApiUrl;
  final String orchardServiceAccountName;
  final String orchardServiceAccountToken;
  final String lokiUrl;
  final String internalLokiUrl;

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
    final baseVmName = Platform.environment['BASE_VM_NAME'] ?? 'base-macos';
    final orchardApiUrl =
        Platform.environment['ORCHARD_API_URL'] ??
        'https://orchard-controller:6120';

    final envName = Platform.environment['ORCHARD_SERVICE_ACCOUNT_NAME'];
    final envToken = Platform.environment['ORCHARD_SERVICE_ACCOUNT_TOKEN'];

    final ({String name, String token}) orchardCredentials;
    if (envName != null &&
        envName.isNotEmpty &&
        envToken != null &&
        envToken.isNotEmpty) {
      orchardCredentials = (name: envName, token: envToken);
    } else {
      orchardCredentials = _loadOrchardCredentials();
    }

    final internalLokiUrl =
        Platform.environment['LOKI_URL'] ?? 'http://loki:3100';
    final lokiUrl =
        Platform.environment['LOKI_URL_FOR_VM'] ?? 'http://192.168.64.1:3100';

    return Config(
      serverUrl: getRequiredEnv('OPENCI_SERVER_URL'),
      baseVmName: baseVmName,
      internalApiKey: getRequiredEnv('INTERNAL_API_KEY'),
      buildJobId: getRequiredEnv('BUILD_JOB_ID'),
      sentryDsn: Platform.environment['SENTRY_DSN'],
      orchardApiUrl: orchardApiUrl,
      orchardServiceAccountName: orchardCredentials.name,
      orchardServiceAccountToken: orchardCredentials.token,
      lokiUrl: lokiUrl,
      internalLokiUrl: internalLokiUrl,
    );
  }
}
