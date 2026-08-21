import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:genuine_ci_cli/src/api/api_service_factory.dart';
import 'package:genuine_ci_cli/src/commands/sync/sync_secrets_command.dart';
import 'package:genuine_ci_cli/src/config/config_storage.dart';
import 'package:genuine_ci_cli/src/generator/secrets_code_generator.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template register_secret_command}
///
/// `genuineci register secret`
/// A [Command] to register or update a secret in Secret Manager.
/// {@endtemplate}
class RegisterSecretCommand extends Command<int> {
  /// {@macro register_secret_command}
  RegisterSecretCommand({
    required Logger logger,
    ConfigStorage? configStorage,
    ApiServiceFactory? apiServiceFactory,
    SecretsCodeGenerator? generator,
  })  : _logger = logger,
        _configStorage = configStorage ?? ConfigStorage(),
        _apiServiceFactory = apiServiceFactory ?? defaultApiServiceFactory,
        _generator = generator ?? const SecretsCodeGenerator() {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Secret name (e.g. SLACK_WEBHOOK_URL)',
      )
      ..addOption(
        'value',
        abbr: 'v',
        help: 'Secret value',
      )
      ..addOption(
        'from-file',
        abbr: 'f',
        help:
            'Path to a file containing the secret value (e.g. key.p8, '
            'service-account.json)',
      )
      ..addOption(
        'team-id',
        help: 'Team ID to register the secret into',
      )
      ..addFlag(
        'sync',
        defaultsTo: true,
        help:
            'Automatically sync secrets and regenerate Dart code after '
            'registration',
      );
  }

  @override
  String get name => 'secret';

  @override
  String get description => 'Register or update a secret in Secret Manager.';

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

    var secretName = argResults?['name'] as String?;
    var secretValue = argResults?['value'] as String?;
    final fromFilePath = argResults?['from-file'] as String?;

    if (secretName == null || secretName.isEmpty) {
      secretName =
          _logger.prompt('Enter Secret Name (e.g. APP_STORE_KEY):').trim();
    }

    if (secretName.isEmpty) {
      _logger.err('Secret name cannot be empty.');
      return ExitCode.usage.code;
    }

    if (fromFilePath != null && fromFilePath.isNotEmpty) {
      final file = File(fromFilePath);
      if (!file.existsSync()) {
        _logger.err('File not found: $fromFilePath');
        return ExitCode.noInput.code;
      }
      secretValue = file.readAsStringSync().trim();
    } else if (secretValue == null || secretValue.isEmpty) {
      secretValue = _logger.prompt('Enter Secret Value:').trim();
    }

    if (secretValue.isEmpty) {
      _logger.err('Secret value cannot be empty.');
      return ExitCode.usage.code;
    }

    final registerProgress = _logger.progress(
      'Registering secret "$secretName" for team "$teamId"',
    );

    final api = _apiServiceFactory(config);
    final response = await api.saveSecret(teamId, {
      'name': secretName,
      'value': secretValue,
    });

    if (!response.isSuccessful) {
      registerProgress.fail();
      _logger.err(
        'Failed to register secret (${response.statusCode}): '
        '${response.error}',
      );
      return ExitCode.software.code;
    }

    registerProgress.complete('Registered secret "$secretName"');
    _logger.success('Secret "$secretName" registered successfully!');

    final shouldSync = argResults?['sync'] as bool? ?? true;
    if (shouldSync) {
      final syncCommand = SyncSecretsCommand(
        logger: _logger,
        configStorage: _configStorage,
        apiServiceFactory: _apiServiceFactory,
        generator: _generator,
      );
      return syncCommand.run();
    }

    return ExitCode.success.code;
  }
}
