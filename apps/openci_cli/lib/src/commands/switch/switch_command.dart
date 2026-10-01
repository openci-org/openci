import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../i18n/i18n.dart';
import 'switch_team_command.dart';

class SwitchCommand extends Command<int> {
  @override
  final String name = 'switch';

  @override
  String get description => t.switchCommand.description;

  SwitchCommand({required Logger logger}) {
    addSubcommand(SwitchTeamCommand(logger: logger));
  }
}
