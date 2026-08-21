import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:genuine_ci_cli/src/api/api_service_factory.dart';
import 'package:genuine_ci_cli/src/config/config_storage.dart';
import 'package:genuine_ci_cli/src/generator/secrets_code_generator.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// {@template sync_secrets_command}
///
/// `genuineci sync secrets`
/// A [Command] to fetch registered secrets and generate type-safe Dart code.
/// {@endtemplate}
class SyncSecretsCommand extends Command<int> {
  /// {@macro sync_secrets_command}
  SyncSecretsCommand({
    required Logger logger,
    ConfigStorage? configStorage,
    ApiServiceFactory? apiServiceFactory,
    SecretsCodeGenerator? generator,
  }) : _logger = logger,
       _configStorage = configStorage ?? ConfigStorage(),
       _apiServiceFactory = apiServiceFactory ?? defaultApiServiceFactory,
       _generator = generator ?? const SecretsCodeGenerator() {
    argParser
      ..addOption(
        'team-id',
        help: 'Team ID containing the secrets',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path for generated secrets code',
        defaultsTo: 'genuine_ci/secrets.g.dart',
      );
  }

  @override
  String get name => 'secrets';

  @override
  String get description =>
      'Sync registered secrets from Secret Manager and generate '
      'type-safe Dart code.';

  final Logger _logger;
  final ConfigStorage _configStorage;
  final ApiServiceFactory _apiServiceFactory;
  final SecretsCodeGenerator _generator;

  String? _getOption(String name) {
    if (argResults != null && argResults!.options.contains(name)) {
      final value = argResults![name];
      if (value is String && value.isNotEmpty) return value;
    }
    if (globalResults != null && globalResults!.options.contains(name)) {
      final value = globalResults![name];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  Future<int> run() async {
    final serverUrl = _getOption('server-url');
    final token = _getOption('token');
    final teamIdOption = _getOption('team-id');

    final config = _configStorage.resolveConfig(
      serverUrlOption: serverUrl,
      tokenOption: token,
      teamIdOption: teamIdOption,
    );

    final teamId = config.teamId;
    if (teamId == null || teamId.isEmpty) {
      _logger.err(
        'Team ID is required. Specify via --team-id, genuineci.yaml, '
        'or `genuineci login`.',
      );
      return ExitCode.usage.code;
    }

    if (config.token == null || config.token!.isEmpty) {
      _logger.err(
        'Authentication token is missing. Please run `genuineci login`.',
      );
      return ExitCode.usage.code;
    }

    final fetchProgress = _logger.progress(
      'Fetching secrets for team "$teamId" from ${config.serverUrl}',
    );

    final api = _apiServiceFactory(config);
    final response = await api.getSecrets(teamId);

    if (!response.isSuccessful) {
      fetchProgress.fail();
      _logger.err(
        'Failed to fetch secrets (${response.statusCode}): '
        '${response.error ?? response.body}',
      );
      return ExitCode.software.code;
    }

    final body = response.body ?? {};
    final secretsList = body['secrets'] as List<dynamic>? ?? [];

    final secretNames = <String>[];
    for (final item in secretsList) {
      if (item is Map<String, dynamic> && item['name'] is String) {
        secretNames.add(item['name'] as String);
      }
    }

    fetchProgress.complete('Fetched ${secretNames.length} secret(s)');

    final code = _generator.generate(secretNames);

    final outputPath =
        argResults?['output'] as String? ?? 'genuine_ci/secrets.g.dart';
    final outputFile = File(outputPath);

    if (!outputFile.parent.existsSync()) {
      outputFile.parent.createSync(recursive: true);
    }

    outputFile.writeAsStringSync(code);

    _logger.success(
      'Successfully synced ${secretNames.length} secret(s) -> '
      '${p.normalize(outputFile.path)}',
    );
    return ExitCode.success.code;
  }
}
