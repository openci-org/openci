import 'package:args/command_runner.dart';
import 'package:genuine_ci_cli/src/api/api_service_factory.dart';
import 'package:genuine_ci_cli/src/commands/sync/sync_secrets_command.dart';
import 'package:genuine_ci_cli/src/config/config_storage.dart';
import 'package:genuine_ci_cli/src/generator/secrets_code_generator.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template sync_command}
///
/// `genuineci sync`
/// A [Command] group for synchronizing remote resources with local project.
/// {@endtemplate}
class SyncCommand extends Command<int> {
  /// {@macro sync_command}
  SyncCommand({
    required Logger logger,
    ConfigStorage? configStorage,
    ApiServiceFactory? apiServiceFactory,
    SecretsCodeGenerator? generator,
  }) {
    addSubcommand(
      SyncSecretsCommand(
        logger: logger,
        configStorage: configStorage,
        apiServiceFactory: apiServiceFactory,
        generator: generator,
      ),
    );
  }

  @override
  String get name => 'sync';

  @override
  String get description => 'Sync remote resources with local project.';
}
