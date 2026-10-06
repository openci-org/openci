import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../credential_store/credential_store.dart';
import '../../i18n/i18n.dart';
import 'setup_asc_keys_command.dart';

class SetupCommand extends Command<int> {
  @override
  final String name = 'setup';

  @override
  String get description => t.setup.description;

  SetupCommand({
    required Logger logger,
    CredentialStore? credentialStore,
    Future<File> Function()? prepareAsc,
  }) {
    addSubcommand(
      SetupAscKeysCommand(
        logger: logger,
        credentialStore: credentialStore,
        prepareAsc: prepareAsc,
      ),
    );
  }
}
