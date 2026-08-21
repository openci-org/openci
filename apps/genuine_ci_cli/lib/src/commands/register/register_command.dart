import 'package:args/command_runner.dart';
import 'package:genuine_ci_cli/src/api/api_service_factory.dart';
import 'package:genuine_ci_cli/src/commands/register/register_secret_command.dart';
import 'package:genuine_ci_cli/src/config/config_storage.dart';
import 'package:genuine_ci_cli/src/generator/secrets_code_generator.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template register_command}
///
/// `genuineci register`
/// A [Command] group for registering resources with Genuine CI.
/// {@endtemplate}
class RegisterCommand extends Command<int> {
  /// {@macro register_command}
  RegisterCommand({
    required Logger logger,
    ConfigStorage? configStorage,
    ApiServiceFactory? apiServiceFactory,
    SecretsCodeGenerator? generator,
  }) {
    addSubcommand(
      RegisterSecretCommand(
        logger: logger,
        configStorage: configStorage,
        apiServiceFactory: apiServiceFactory,
        generator: generator,
      ),
    );
  }

  @override
  String get name => 'register';

  @override
  String get description => 'Register resources with Genuine CI.';
}
