import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../credential_store/credential_store.dart';
import '../../i18n/i18n.dart';
import 'list_secrets_command.dart';
import 'list_teams_command.dart';

class ListCommand extends Command<int> {
  @override
  final String name = 'list';

  @override
  String get description => t.list.description;

  ListCommand({required Logger logger, CredentialStore? credentialStore}) {
    addSubcommand(
      ListSecretsCommand(logger: logger, credentialStore: credentialStore),
    );
    addSubcommand(
      ListTeamsCommand(logger: logger, credentialStore: credentialStore),
    );
  }
}
