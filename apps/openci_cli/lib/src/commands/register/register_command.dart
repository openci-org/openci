import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../i18n/i18n.dart';
import 'register_secret_command.dart';
import 'register_secret_file_command.dart';

class RegisterCommand extends Command<int> {
  @override
  final String name = 'register';

  @override
  String get description => t.register.description;

  RegisterCommand({required Logger logger}) {
    addSubcommand(RegisterSecretCommand(logger: logger));
    addSubcommand(RegisterSecretFileCommand(logger: logger));
  }
}
