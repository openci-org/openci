import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../i18n/i18n.dart';
import 'dev_start_command.dart';

class DevCommand extends Command<int> {
  @override
  final String name = 'dev';

  @override
  String get description => t.dev.description;

  DevCommand({required Logger logger}) {
    addSubcommand(DevStartCommand(logger: logger));
  }
}
