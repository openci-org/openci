import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../i18n/i18n.dart';
import 'setup_asc_keys_command.dart';
import 'setup_ios_certificate_key_command.dart';

class SetupCommand extends Command<int> {
  @override
  final String name = 'setup';

  @override
  String get description => t.setup.description;

  SetupCommand({required Logger logger}) {
    addSubcommand(SetupAscKeysCommand(logger: logger));
    addSubcommand(SetupIosCertificateKeyCommand(logger: logger));
  }
}
