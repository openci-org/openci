import 'dart:io';

import 'package:yaml/yaml.dart';

class ProcessorConfig {
  ProcessorConfig({
    required this.serverUrl,
    required this.baseVmName,
    required this.internalApiKey,
    this.sentryDsn,
    this.maxConcurrentJobs = 3,
    this.orchardApiUrl = 'https://orchard-controller:6120',
    this.orchardServiceAccountName = 'openci',
    this.orchardServiceAccountToken = '',
    this.vmPrepareTimeoutMinutes = 15,
  });

  final String serverUrl;
  final String baseVmName;
  final String internalApiKey;
  final String? sentryDsn;
  final int maxConcurrentJobs;

  final String orchardApiUrl;
  final String orchardServiceAccountName;
  final String orchardServiceAccountToken;
  final int vmPrepareTimeoutMinutes;

  static String _getRequired(String key) {
    final value = Platform.environment[key];
    if (value == null || value.isEmpty) {
      throw StateError('Required environment variable $key is not set.');
    }
    return value;
  }

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

  factory ProcessorConfig.fromEnvironment() {
    final maxConcurrentJobsStr =
        Platform.environment['OPENCI_MAX_CONCURRENT_JOBS'] ?? '2';
    final maxConcurrentJobs = int.tryParse(maxConcurrentJobsStr) ?? 2;

    final vmPrepareTimeoutStr =
        Platform.environment['OPENCI_VM_PREPARE_TIMEOUT_MINUTES'] ?? '15';
    final vmPrepareTimeoutMinutes = int.tryParse(vmPrepareTimeoutStr) ?? 15;

    final baseVmName = Platform.environment['BASE_VM_NAME'] ?? 'tahoe-base';

    final orchardApiUrl =
        Platform.environment['ORCHARD_API_URL'] ??
        'https://orchard-controller:6120';

    final orchardCredentials = _loadOrchardCredentials();

    return ProcessorConfig(
      serverUrl: _getRequired('OPENCI_SERVER_URL'),
      baseVmName: baseVmName,
      internalApiKey: _getRequired('INTERNAL_API_KEY'),
      sentryDsn: Platform.environment['SENTRY_DSN'],
      maxConcurrentJobs: maxConcurrentJobs,
      orchardApiUrl: orchardApiUrl,
      orchardServiceAccountName: orchardCredentials.name,
      orchardServiceAccountToken: orchardCredentials.token,
      vmPrepareTimeoutMinutes: vmPrepareTimeoutMinutes,
    );
  }
}
