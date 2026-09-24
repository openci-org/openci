import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../i18n/i18n.dart';
import 'sync_paths_command.dart';
import 'sync_secrets_command.dart';

class SyncCommand extends Command<int> {
  @override
  final String name = 'sync';

  @override
  String get description => t.sync.description;

  SyncCommand({required Logger logger}) {
    addSubcommand(SyncPathsCommand(logger: logger));
    addSubcommand(SyncSecretsCommand(logger: logger));
  }
}
