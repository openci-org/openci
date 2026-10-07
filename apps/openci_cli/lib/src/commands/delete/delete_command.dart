import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../credential_store/credential_store.dart';
import '../../i18n/i18n.dart';
import 'delete_secret_command.dart';

class DeleteCommand extends Command<int> {
  @override
  final String name = 'delete';

  @override
  String get description => t.delete.description;

  DeleteCommand({required Logger logger, CredentialStore? credentialStore}) {
    addSubcommand(
      DeleteSecretCommand(logger: logger, credentialStore: credentialStore),
    );
  }
}
